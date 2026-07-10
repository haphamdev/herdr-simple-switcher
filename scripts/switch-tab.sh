#!/usr/bin/env bash
set -euo pipefail

for cmd in fzf jq; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "$cmd is required but not found" >&2; exit 1; }
done

HERDR="${HERDR_BIN_PATH:-herdr}"

workspace_json=$("$HERDR" workspace list)
current_ws=$(echo "$workspace_json" | jq -r '.result.workspaces[] | select(.focused == true) | .workspace_id')
current_ws_label=$(echo "$workspace_json" | jq -r '.result.workspaces[] | select(.focused == true) | .label')

selected=$("$HERDR" tab list --workspace "$current_ws" | \
  jq -r '.result.tabs[] |
    (if .focused then "* " else "  " end) +
    (.number | tostring) + ": " + .label + "\t" + .tab_id' | \
  fzf --delimiter=$'\t' --with-nth=1 \
      --prompt="Tab > " \
      --header="workspace: ${current_ws_label}" \
      --reverse --no-multi --exit-0 || true)

if [[ -n "$selected" ]]; then
  tab_id=$(echo "$selected" | cut -f2)
  "$HERDR" tab focus "$tab_id" >/dev/null
fi
