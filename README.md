# Simple Switcher

A [Herdr](https://herdr.dev) plugin for fuzzy switching between workspaces, tabs, and agents, and opening projects in new tabs, using [fzf](https://github.com/junegunn/fzf).

## Requirements

- [Herdr](https://herdr.dev) >= 0.7.0
- [fzf](https://github.com/junegunn/fzf)
- [jq](https://jqlang.github.io/jq/)
- [fd](https://github.com/sharkdp/fd) (required by **Open Project**)

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

### Open Project

Fuzzy-select a project and open it in a new tab. Projects are discovered under a configurable root laid out as `<workspace>/<project>` (e.g. `personal/togglr`). The project opens in a new tab on the Herdr workspace whose label matches `<workspace>`; if no such workspace exists, it is created.

Configure the projects root by copying the example config into the plugin config dir:

```sh
cp config.example.env "$(herdr plugin config-dir simple-switcher)/config.env"
```

`config.env` sets `PROJECTS_ROOT` (a leading `~` and `$HOME` are expanded); `HERDR_SIMPLE_SWITCHER_PROJECTS_ROOT` overrides it at runtime. A projects root is **required** — there is no default.

If neither is set, the picker shows setup instructions instead of a project list, and a startup hook posts a Herdr notification each session reminding you to configure it.

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

[[keys.command]]
key = "prefix+p"
type = "plugin_action"
command = "simple-switcher.open-project"
description = "open project"
```

Each keybinding above uses `type = "plugin_action"` to invoke a plugin action (`simple-switcher.<id>`); the action opens the matching popup pane. All actions open as popups — pick an item and the popup closes, or press `Esc` to cancel.

Alternatively, open a pane directly with a shell command (no action indirection):

```toml
[[keys.command]]
key = "prefix+p"
type = "shell"
command = "herdr plugin pane open --plugin simple-switcher --entrypoint open-project"
```

## License

MIT
