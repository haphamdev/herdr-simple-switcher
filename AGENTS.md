# Repository Guidelines

## Project Overview

`herdr-simple-switcher` is a [Herdr](https://herdr.dev) plugin that adds four interactive fuzzy-select popups for navigating a Herdr session: **switch workspace**, **switch tab**, **switch agent**, and **open project**. The three switch actions query the `herdr` CLI, format with `jq`, present via `fzf`, and apply with a `herdr … focus` call. **Open project** discovers git repos under a configurable root and opens the chosen one in a new tab (creating the workspace if needed). Pure bash — no build step, no compiled source. MIT licensed.

## Architecture & Data Flow

The plugin is manifest-driven. `herdr-plugin.toml` declares four `[[panes]]`, each spawning a bash script as a `popup`. The three switch scripts follow the identical pipeline:

```
herdr <entity> list           # query state as JSON
  → jq -r '…'                 # format into "display\tID" lines
  → fzf --with-nth=1          # interactive fuzzy select (display col 1)
  → cut -f2                   # extract the ID (col 2)
  → herdr <entity> focus <ID> # apply the selection
```

Pattern: **query → format → interact → apply**. `open-project.sh` extends it with a discovery + create step:

```
fd -H -t d '^\.git$' $PROJECTS_ROOT  # find repos, emit "ws/proj\tws\tabs-path"
  → fzf --with-nth=1                 # pick a project
  → herdr workspace list | jq        # find workspace whose label == ws
  → herdr tab create --workspace ID --cwd PATH --label PROJ   # reuse workspace
     (or herdr workspace create --cwd PATH --label ws, then tab rename)  # create it
  → herdr workspace focus / herdr tab focus                   # apply
```

A `[[startup]]` hook (`scripts/startup-check.sh`) runs once per session and posts a `herdr notification show` toast when the projects root is unconfigured — startup stdout only reaches the plugin log, so user-facing messages must go through the notification CLI.

Scripts are independent, stateless, argument-free, and interactive-only (no automated assertions).

## Key Directories

- `scripts/` — the four action scripts (one bash file per pane) plus `startup-check.sh` (startup hook).
- `.claude/` — local agent permission config (`settings.local.json`).
- Repo root — plugin manifest, `config.example.env`, and docs. No `src/`, no `tests/`.

## Important Files

- `herdr-plugin.toml` — plugin manifest and entry points. Top-level: `id = "simple-switcher"`, `version = "0.3.0"`, `min_herdr_version = "0.7.0"`, `platforms = ["linux", "macos"]`. One `[[startup]]` hook and four `[[panes]]` mapping `id` → `command = ["bash", "scripts/<name>.sh"]`.
- `scripts/switch-workspace.sh` — lists workspaces (number, label, tab count with `tab`/`tabs` pluralization); focuses via `herdr workspace focus <workspace_id>`.
- `scripts/switch-tab.sh` — resolves the current workspace, lists its tabs (`herdr tab list --workspace <WID>`), shows the workspace label in the fzf header; focuses via `herdr tab focus <tab_id>`.
- `scripts/switch-agent.sh` — lists agents across all workspaces (name, `[agent_status]`, cwd), filters empty agents; focuses via `herdr agent focus <pane_id>`.
- `scripts/open-project.sh` — `fd`-discovers git repos under `PROJECTS_ROOT` (`<workspace>/<project>` layout), picks one, then reuses or creates the matching-label workspace and opens the project in a new tab via `herdr tab create --cwd <path> --label <project>` (parses `.result.tab.tab_id` / `.result.workspace.workspace_id`). Projects root resolves as `HERDR_SIMPLE_SWITCHER_PROJECTS_ROOT` env > `PROJECTS_ROOT` in `$HERDR_PLUGIN_CONFIG_DIR/config.env` > `~/projects`.
- `scripts/startup-check.sh` — startup hook; if neither `HERDR_SIMPLE_SWITCHER_PROJECTS_ROOT` nor `PROJECTS_ROOT` (in `config.env`) is set, fires `herdr notification show` to prompt setup. Exits 0 otherwise.
- `config.example.env` — template for the user's `config.env` (copied into the plugin config dir); sets `PROJECTS_ROOT`.
- `README.md` — install (`herdr plugin install hapham/herdr-simple-switcher`), requirements, and example keybindings.

## Development Commands

There is no build, lint, or test tooling configured.

```bash
# Install the plugin into Herdr
herdr plugin install hapham/herdr-simple-switcher

# Run an action script directly (for manual smoke testing)
bash scripts/switch-workspace.sh
bash scripts/switch-tab.sh
bash scripts/switch-agent.sh
bash scripts/open-project.sh

# Point scripts at a specific herdr binary
HERDR_BIN_PATH=/path/to/herdr bash scripts/switch-agent.sh

# Point Open Project at a projects root without a config file
HERDR_SIMPLE_SWITCHER_PROJECTS_ROOT=~/code bash scripts/open-project.sh
```

Actions are also invoked from user keymaps as `simple-switcher.<pane-id>` (e.g. `simple-switcher.switch-workspace`).

## Code Conventions & Common Patterns

All scripts are deliberately uniform — match this style exactly when adding or editing:

- **Shebang / strict mode**: `#!/usr/bin/env bash` then `set -euo pipefail`.
- **Dependency check** at top:
  ```bash
  for cmd in fzf jq; do
    command -v "$cmd" >/dev/null 2>&1 || {
      echo "$cmd is required but not found" >&2
      exit 1
    }
  done
  ```
- **Binary override**: `HERDR="${HERDR_BIN_PATH:-herdr}"`; always call `"$HERDR"` (quoted).
- **Formatting**: `jq -r` builds tab-delimited `display\tID` lines; focused rows are prefixed with `"* "` vs `"  "` via `(if .focused then "* " else "  " end)`.
- **Selection**: `fzf --delimiter=$'\t' --with-nth=1 --prompt="<Label> > " --reverse --no-multi --exit-0 || true` — `|| true` swallows fzf exit 130 on Esc so `set -e` doesn't abort.
- **Apply**: guard with `if [[ -n "$selected" ]]; then …`, extract ID with `cut -f2`, redirect focus/mutation output to `>/dev/null`.
- **Config**: plugin owns its config format (Herdr has no config API). Read user config from `$HERDR_PLUGIN_CONFIG_DIR/config.env` (sourced), allow an env-var override, and fall back to a sane default — see `open-project.sh` resolving `PROJECTS_ROOT`.
- **Naming**: hyphenated script files (`<verb>-<entity>.sh`); lowercase locals (`selected`, `pane_id`, `workspace_id`, `tab_id`, `project_path`); uppercase constants (`HERDR`); no spaces around `=`; double-quote all variable expansions.

## Runtime/Tooling Preferences

- **Runtime**: `bash`. No Node, Bun, Rust, or package manager — do not introduce one.
- **Required tools on the host**: `herdr` CLI (>= 0.7.0), `fzf`, `jq`, and `fd` (Open Project only).
- **Manifest schema**: Herdr `[[panes]]` and `[[startup]]` (v0.7.0+). Panes: `id`, `title`, `placement = "popup"`, `command`. Startup: `command` (one-shot, async; output goes to the plugin log, not the user — use `herdr notification show` for user-facing messages).
- `.claude/settings.local.json` restricts agent Bash to `rtk ls *` and `herdr agent *`, and WebFetch to the `herdr.dev` domain.
- **Plugin runtime env** (injected by Herdr): call the CLI via `HERDR_BIN_PATH`; read user config from `HERDR_PLUGIN_CONFIG_DIR`; durable state (if ever needed) goes in `HERDR_PLUGIN_STATE_DIR` — never write into `HERDR_PLUGIN_ROOT` (managed checkout).

## Testing & QA

No tests, test framework, or CI exist in this repo. QA is manual: run a script and exercise selection + Esc against a live `herdr` session.

If adding automated coverage, the idiomatic choice for these scripts is **shellcheck** (static lint) plus **bats** (mock the `herdr` CLI, assert `jq` formatting and the `cut -f2` ID extraction, verify the correct `focus` invocation). Do not claim tests exist until they do.
