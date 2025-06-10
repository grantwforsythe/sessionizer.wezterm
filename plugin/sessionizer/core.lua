local wezterm = require("wezterm")
local act = wezterm.action
local mux = wezterm.mux

local helpers = require("sessionizer.helpers")

---@class SessionizerConfig
---@field paths string[]
---@field ignore_default_workspace boolean
---@field fd_path? string
local config = {
	paths = { wezterm.home_dir },
	ignore_default_workspace = true,
}

--- Returns the file descriptor path as a string.
--- @return string fd_path The file descriptor path.
local function get_fd_path()
	local args = helpers.is_windows and "dir /s /b %USERPROFILE%\\AppData\\Local\\Microsoft\\WinGet\\Packages\\fd.exe"
		or "which fd"

	local stdout = helpers.run_child_process(args)
	-- On Windows, the output may contain a newline character at the end
	local fd_path = string.gsub(stdout, "[\r\n]", "")

	return fd_path
end

---@class InputSelector
---@field id string
---@field label string

---Retrieve the directories found within the base_path table
---@return InputSelector[]
local function get_directories(paths)
	--- @type InputSelector[]
	local folders = {}

	local stdout = helpers.run_child_process(
		config.fd_path or get_fd_path() .. " . -a --type d --max-depth 1 " .. table.concat(config.paths, " ")
	)

	for _, path in ipairs(wezterm.split_by_newlines(stdout)) do
		table.insert(folders, { id = path, label = helpers.get_short_path(path) })
	end

	return folders
end

---Get a list of active workspaces.
---@return InputSelector[]
local function get_active_workspaces()
	--- @type InputSelector[]
	local workspaces = {}

	for _, workspace in ipairs(mux.get_workspace_names()) do
		if config.ignore_default_workspace and workspace == "default" then
			goto continue
		end

		table.insert(workspaces, {
			id = helpers.get_full_path(workspace),
			label = wezterm.format({
				{ Foreground = { Color = "#fabd2f" } },
				{ Text = wezterm.nerdfonts.cod_window .. " " .. workspace },
				{ Attribute = { Intensity = "Bold" } },
			}),
		})
		::continue::
	end

	return workspaces
end

---@class Sessionizer
---@field workspace_switcher fun(): any
---@field active_workspaces fun(): any
---@field setup fun(opts: { paths: string[], fd_path?: string })
local M = {}

M.workspace_switcher = function()
	return wezterm.action_callback(function(window, pane)
		local active_workspaces = get_active_workspaces()
		local inactive_workspaces = get_directories()

		-- Build a set of active workspace ids for quick lookup
		local active_ids = {}
		-- Populate the active_ids set with the ids of currently active workspaces
		for _, ws in ipairs(active_workspaces) do
			active_ids[ws.id] = true
		end

		-- Only add workspaces that are not already active
		for _, ws in ipairs(inactive_workspaces) do
			if not active_ids[ws.id] then
				table.insert(active_workspaces, ws)
			end
		end

		window:perform_action(
			act.InputSelector({
				action = wezterm.action_callback(function(inner_window, inner_pane, id, label)
					if not id and not label then
						-- INFO: Do nothing
					else
						local full_path = string.gsub(label, "^~", wezterm.home_dir)
						wezterm.log_info("Switching to workspace: " .. full_path)

						if full_path:sub(1, 1) == "/" or full_path:sub(3, 3) == "\\" then
							inner_window:perform_action(
								act.SwitchToWorkspace({
									name = label,
									spawn = {
										label = "Workspace: " .. label,
										cwd = full_path,
									},
								}),
								inner_pane
							)
						else
							inner_window:perform_action(
								act.SwitchToWorkspace({
									name = id,
								}),
								inner_pane
							)
						end
					end
				end),
				title = "Wezterm Sessionizer",
				choices = active_workspaces,
				fuzzy = true,
			}),
			pane
		)
	end)
end

M.active_workspaces = function()
	return act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" })
end

M.setup = function(opts)
	local transformed_paths = {}
	for _, v in ipairs(opts.paths) do
		local transformed_path = string.gsub(v, "~", wezterm.home_dir)
		table.insert(transformed_paths, transformed_path)
	end

	if #transformed_paths > 0 then
		config.paths = transformed_paths
	end

	if opts.fd_path ~= nil then
		config.fd_path = opts.fd_path
	end
end

return M
