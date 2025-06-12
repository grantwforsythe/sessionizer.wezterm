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
	add_workspace_to_zoxide = false,
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

---Get a list of active workspaces.
---@return InputSelector[]
local function get_active_workspaces_to_set()
	local set = {}

	for _, workspace in ipairs(mux.get_workspace_names()) do
		if not (config.ignore_default_workspace and workspace == "default") then
			set[helpers.get_full_path(workspace)] = true
		end
	end

	return set
end

---@class InputSelector
---@field id string
---@field label string

---Retrieve the directories found within the base_path table
---@return InputSelector[]
local function get_workspaces()
	local active_workspaces_set = get_active_workspaces_to_set()
	local paths = helpers.map(config.paths, function(v)
		local transformed_path = string.gsub(v, "~", wezterm.home_dir)
		return transformed_path
	end)

	--- @type InputSelector[]
	local folders = {}

	local stdout = helpers.run_child_process(
		config.fd_path or get_fd_path() .. " . -a --type d --max-depth 1 " .. table.concat(paths, " ")
	)

	for _, path in ipairs(wezterm.split_by_newlines(stdout)) do
		if not active_workspaces_set[path] then
			table.insert(folders, { id = path, label = helpers.get_short_path(path) })
		else
			table.insert(folders, {
				id = path,
				label = wezterm.format({
					{ Foreground = { Color = "#fabd2f" } },
					--{ Text = wezterm.nerdfonts.cod_window .. " " .. workspace },
					{ Text = helpers.get_short_path(path) },
					{ Attribute = { Intensity = "Bold" } },
				}),
			})
		end
	end

	return folders
end

---@class Sessionizer
---@field workspace_switcher fun(): any
---@field active_workspaces fun(): any
---@field setup fun(opts: { paths: string[], fd_path?: string })
local M = {}

M.workspace_switcher = function()
	return wezterm.action_callback(function(window, pane)
		local workspaces = get_workspaces()

		window:perform_action(
			act.InputSelector({
				action = wezterm.action_callback(function(inner_window, inner_pane, id, label)
					if not id and not label then
						return
					end

					if id:sub(1, 1) == "/" or id:sub(3, 3) == "\\" then
						inner_window:perform_action(
							act.SwitchToWorkspace({
								name = label,
								spawn = {
									label = "Workspace: " .. label,
									cwd = id,
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

					if config.add_workspace_to_zoxide then
						wezterm.log_info("Adding workspace to zoxide: " .. id)
						helpers.run_child_process("zoxide add " .. id)
					end
				end),
				title = "Wezterm Sessionizer",
				choices = workspaces,
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
	for key, value in pairs(opts) do
		if config[key] ~= nil then
			config[key] = value
		else
			wezterm.log_warn("Unknown option: " .. key)
		end
	end
end

return M
