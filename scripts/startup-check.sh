#!/usr/bin/env bash
set -euo pipefail

# Startup hook: nudge the user to configure Open Project's projects root when it
# is not set. Runs at session start; output goes to the plugin log, so the
# user-facing message is delivered via `herdr notification show`.

HERDR="${HERDR_BIN_PATH:-herdr}"
config_dir="${HERDR_PLUGIN_CONFIG_DIR:-}"
config_file=""
[[ -n "$config_dir" ]] && config_file="$config_dir/config.env"

# Configured if config.env defines PROJECTS_ROOT.
configured=0
if [[ -n "$config_dir" && -f "$config_file" ]]; then
  # shellcheck source=/dev/null
  . "$config_file"
  [[ -n "${PROJECTS_ROOT:-}" ]] && configured=1
fi

if [[ "$configured" -eq 0 ]]; then
  "$HERDR" notification show "Simple Switcher setup" \
    --body "Open Project needs a projects root. Set PROJECTS_ROOT in ${config_file:-the plugin config.env} (see config.example.env)." \
    >/dev/null 2>&1 || true
fi
