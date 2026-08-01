#!/usr/bin/env bash
set -euo pipefail

for cmd in fd fzf jq; do
  command -v "$cmd" >/dev/null 2>&1 || {
    echo "$cmd is required but not found" >&2
    exit 1
  }
done

HERDR="${HERDR_BIN_PATH:-herdr}"

# Popups close when the command exits, so pause on error to keep the message
# readable before the popup vanishes.
die() {
  printf '%s\n\nPress Enter to close…' "$1" >&2
  read -r _ || true
  exit 1
}

# Resolve the projects root from the plugin config file (no env override, no default).
projects_root=""
if [[ -n "${HERDR_PLUGIN_CONFIG_DIR:-}" ]]; then
  config_file="$HERDR_PLUGIN_CONFIG_DIR/config.env"
  if [[ -f "$config_file" ]]; then
    # shellcheck source=/dev/null
    . "$config_file"
    projects_root="${PROJECTS_ROOT:-}"
  fi
fi

if [[ -z "$projects_root" ]]; then
  die "Open Project is not configured.

Set a projects root, then try again:
  echo 'PROJECTS_ROOT=\"\$HOME/projects\"' > \"${HERDR_PLUGIN_CONFIG_DIR:-<plugin config dir>}/config.env\""
fi

projects_root="${projects_root/#\~/$HOME}"

if [[ ! -d "$projects_root" ]]; then
  die "Projects root not found: $projects_root"
fi

# List every git project as "<workspace>/<project>\t<workspace>\t<abs-path>".
selected=$(fd -H -t d '^\.git$' "$projects_root" \
  --exec sh -c 'p="$1"; ws="$(basename "$(dirname "$p")")"; printf "%s/%s\t%s\t%s\n" "$ws" "$(basename "$p")" "$ws" "$p"' _ {//} |
  sort |
  fzf --delimiter=$'\t' --with-nth=1 \
    --prompt="Project > " \
    --reverse --no-multi --exit-0 || true)

[[ -n "$selected" ]] || exit 0

ws_label=$(printf '%s' "$selected" | cut -f2)
project_path=$(printf '%s' "$selected" | cut -f3)
project_name=$(basename "$project_path")

# Reuse the workspace whose label matches, otherwise create it.
workspace_id=$("$HERDR" workspace list |
  jq -r --arg label "$ws_label" \
    'first(.result.workspaces[] | select(.label == $label) | .workspace_id) // empty')

if [[ -n "$workspace_id" ]]; then
  tab_id=$("$HERDR" tab create --workspace "$workspace_id" \
    --cwd "$project_path" --label "$project_name" --no-focus |
    jq -r '.result.tab.tab_id')
else
  created=$("$HERDR" workspace create --cwd "$project_path" \
    --label "$ws_label" --no-focus)
  workspace_id=$(printf '%s' "$created" | jq -r '.result.workspace.workspace_id')
  tab_id=$(printf '%s' "$created" | jq -r '.result.tab.tab_id')
  # A fresh workspace already opens its first tab at the project cwd; label it.
  "$HERDR" tab rename "$tab_id" "$project_name" >/dev/null
fi

"$HERDR" workspace focus "$workspace_id" >/dev/null
"$HERDR" tab focus "$tab_id" >/dev/null
