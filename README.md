# Sessionizer for Wezterm

---

A tmux like sessionizer for Wezterm that was inspired by [ThePrimeagen's tmux-sessionizer](https://github.com/ThePrimeagen/.dotfiles/blob/master/bin/.local/scripts/tmux-sessionizer)

The sessionizer allows for opening of windows/sessions based on the passed in
directories, as well as fast and intuative switching between active
workspaces/sessions.

This fork uses [zoxide](https://github.com/ajeetdsouza/zoxide) as it works on all major operation systems and has better performance over built in commands.

## Requirements
- [zoxide](https://github.com/ajeetdsouza/zoxide) is used to "jump" between workspaces

## Setup

An example configuration calling the plugin

```lua
local wezterm = require "wezterm"

local config = {}

if wezterm.config_builder then
    config = wezterm.config_builder()
end

--INFO: The sessionizer lverages the `LEADER` mod
config.leader = {
    key = "a",
    mods = "CTRL",
    timeout_milliseconds = 1000
}

config.keys = {}

local sessionizer = wezterm.plugin.require("https://github.com/grantwforsythe/sessionizer.wezterm")
sessionizer.apply_to_config(config)

return config
```

## USEAGE

The sessionizer uses directories being tracked by zoxide. Read the offical documentation for more details on tracking directories.

| Key Combination   | Default | Description                                 |
|-------------------|---------|---------------------------------------------|
| `LEADER` + `f`    | Yes     | Display the sessionizer                     |
| `LEADER` + `s`    | Yes     | Display the active windows/sessions         |

### Change keybinding

```lua
config.keys = {
    -- ... other bindings
    {
        key = "w",
        mods = "CTRL|ALT",
        action = sessionizer.switch_workspace()
    }
}
```
