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

Fuzzy-select a Git project and open it in a new tab.

**How projects are discovered.** Point `PROJECTS_ROOT` at a directory laid out as `<workspace>/<project>`. The plugin runs `fd` to find every Git repository (a `.git` directory) beneath that root and lists each one as `<workspace>/<project>`, where `<workspace>` is the repository's immediate parent directory name.

Given `PROJECTS_ROOT="$HOME/projects"` and this layout:

```
~/projects
├── personal
│   ├── togglr          # Git repo  -> personal/togglr
│   │   └── .git
│   ├── clockwise       # Git repo  -> personal/clockwise
│   │   └── .git
│   └── notes           # no .git   -> ignored
└── work
    └── api             # Git repo  -> work/api
        └── .git
```

the picker shows:

```
personal/clockwise
personal/togglr
work/api
```

**What happens on select.** Choosing `personal/togglr` opens a new tab whose working directory is `~/projects/personal/togglr`, on the Herdr workspace labeled `personal`. If no workspace with that label exists yet, it is created first.

Repositories are matched at any depth, but the workspace label is always the repo's immediate parent directory — so the flat `<workspace>/<project>` layout above is what this action expects.

Create `config.env` in the plugin config directory. Find the exact path with:

```sh
herdr plugin config-dir simple-switcher
```

Then create `config.env` there with your projects root:

```sh
# <config-dir>/config.env
PROJECTS_ROOT="$HOME/projects"
```

A leading `~` and `$HOME` are expanded. A projects root is **required** — there is no default.

If it is not set, the picker shows setup instructions instead of a project list, and a startup hook posts a Herdr notification each session reminding you to configure it.

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
