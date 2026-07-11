# Simple Switcher

A [Herdr](https://herdr.dev) plugin for fuzzy switching between workspaces, tabs, and agents using [fzf](https://github.com/junegunn/fzf).

## Requirements

- [Herdr](https://herdr.dev) >= 0.7.0
- [fzf](https://github.com/junegunn/fzf)
- [jq](https://jqlang.github.io/jq/)

## Installation

```sh
herdr plugin install hapham/herdr-simple-switcher
```

## Actions

### Switch Workspace

Fuzzy-select a workspace to focus. Shows workspace number, label, and tab count.

### Switch Tab

Fuzzy-select a tab within the current workspace. Shows tab number and label.

### Switch Agent

Fuzzy-select an AI agent across all workspaces. Shows agent type, status, and working directory.

## Keymaps

Add keybindings to your Herdr config to trigger each action with a shortcut:

```toml
[[keys.command]]
key = "prefix+w"
type = "plugin_action"
command = "simple-switcher.switch-workspace"
description = "switch workspace"

[[keys.command]]
key = "prefix+t"
type = "plugin_action"
command = "simple-switcher.switch-tab"
description = "switch tab"

[[keys.command]]
key = "prefix+a"
type = "plugin_action"
command = "simple-switcher.switch-agent"
description = "switch agent"
```

All three actions open as overlays — pick an item and the overlay closes, or press `Esc` to cancel.

## License

MIT
