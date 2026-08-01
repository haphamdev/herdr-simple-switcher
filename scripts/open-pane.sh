#!/usr/bin/env bash
set -euo pipefail

# Action launcher: opens one of the plugin's popup panes by entrypoint id.
# Plugin actions (`plugin_action` keybindings) run a command, not a pane, so
# this bridges an action to its popup pane via `herdr plugin pane open`.
#
# Usage: open-pane.sh <entrypoint-id>

HERDR="${HERDR_BIN_PATH:-herdr}"
exec "$HERDR" plugin pane open --plugin simple-switcher --entrypoint "$1"
