#!/usr/bin/env bash
set -euo pipefail

for cmd in fzf jq; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "$cmd is required but not found" >&2; exit 1; }
done

HERDR="${HERDR_BIN_PATH:-herdr}"

selected=$("$HERDR" agent list | \
  jq -r '.result.agents[] |
    (if .focused then "* " else "  " end) +
    .agent + " [" + .agent_status + "] " + .cwd +
    "\t" + .pane_id' | \
  fzf --delimiter=$'\t' --with-nth=1 \
      --prompt="Agent > " \
      --reverse --no-multi --exit-0 || true)

if [[ -n "$selected" ]]; then
  pane_id=$(echo "$selected" | cut -f2)
  "$HERDR" agent focus "$pane_id" >/dev/null
fi
