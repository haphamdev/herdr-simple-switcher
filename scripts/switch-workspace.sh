#!/usr/bin/env bash
set -euo pipefail

for cmd in fzf jq; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "$cmd is required but not found" >&2; exit 1; }
done

HERDR="${HERDR_BIN_PATH:-herdr}"

selected=$("$HERDR" workspace list | \
  jq -r '.result.workspaces[] |
    (if .focused then "* " else "  " end) +
    (.number | tostring) + ": " + .label +
    " (" + (.tab_count | tostring) + " " + (if .tab_count == 1 then "tab" else "tabs" end) + ")" +
    "\t" + .workspace_id' | \
  fzf --delimiter=$'\t' --with-nth=1 \
      --prompt="Workspace > " \
      --reverse --no-multi --exit-0 || true)

if [[ -n "$selected" ]]; then
  workspace_id=$(echo "$selected" | cut -f2)
  "$HERDR" workspace focus "$workspace_id" >/dev/null
fi
