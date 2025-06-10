local wezterm = require("wezterm")

---@alias Set table<string, boolean>

---@class Utils
---@field is_windows boolean
---@field run_child_process fun(cmd: string): string
---@field get_full_path fun(workspace: string): string
---@field get_short_path fun(workspace: string): string
---@field new_set fun(list: string[]): Set
local M = {}

M.is_windows = string.find(wezterm.target_triple, "windows") ~= nil

M.run_child_process = function(cmd)
	local process_args = M.is_windows and { "cmd", "/c", cmd } or { os.getenv("SHELL") or "/bin/sh", "-c", cmd }

	local success, stdout, stderr = wezterm.run_child_process(process_args)

	if not success then
		wezterm.log_error(stderr)
	end

	return stdout
end

M.get_full_path = function(path)
	local full_path = string.gsub(path, "~", wezterm.home_dir)
	return full_path
end

M.get_short_path = function(path)
	local short_path = string.gsub(path, wezterm.home_dir, "~")
	return short_path
end

M.new_set = function(list)
	local set = {}
	for _, v in ipairs(list) do
		set[v] = true
	end
	return set
end

return M
