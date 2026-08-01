#!/usr/bin/env bash
set -euo pipefail

for cmd in fd fzf jq; do
  command -v "$cmd" >/dev/null 2>&1 || {
    echo "$cmd is required but not found" >&2
    exit 1
  }
done

HERDR="${HERDR_BIN_PATH:-herdr}"

# Resolve the projects root: env override > plugin config file > default.
projects_root="${HERDR_SIMPLE_SWITCHER_PROJECTS_ROOT:-}"
if [[ -z "$projects_root" && -n "${HERDR_PLUGIN_CONFIG_DIR:-}" ]]; then
  config_file="$HERDR_PLUGIN_CONFIG_DIR/config.env"
  if [[ -f "$config_file" ]]; then
    # shellcheck source=/dev/null
    . "$config_file"
    projects_root="${PROJECTS_ROOT:-}"
  fi
fi
projects_root="${projects_root:-$HOME/projects}"
projects_root="${projects_root/#\~/$HOME}"

if [[ ! -d "$projects_root" ]]; then
  echo "projects root not found: $projects_root" >&2
  exit 1
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
