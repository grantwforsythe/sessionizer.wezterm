-- NOTE: This is required to ensure that the plugin can be loaded correctly
package.path = package.path .. ";" .. ({ ... })[2]:gsub("init.lua$", "?.lua")

local sessionizer = require("sessionizer.core")

local M = {}

M.apply_to_config = function(config, opts)
	if config == nil or config.keys == nil then
		return
	end

	if opts ~= nil then
		sessionizer.setup(opts)
	end

	table.insert(config.keys, {
		key = "f",
		mods = "CTRL",
		action = sessionizer.workspace_switcher(),
	})

	table.insert(config.keys, {
		key = "s",
		mods = "CTRL",
		action = sessionizer.active_workspaces(),
	})
end

return M
