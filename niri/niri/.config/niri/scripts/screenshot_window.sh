#!/usr/bin/env bash
set -euo pipefail

# Click any window to screenshot it. niri copies the capture to the clipboard and writes it
# to screenshot-path. Escape during the pick cancels without capturing.
# Usage: screenshot_window.sh

window_id="$(niri msg --json pick-window | jq -r '.id // empty')"
[[ -n "${window_id}" ]] || exit 0

niri msg action screenshot-window --id "${window_id}" --write-to-disk true
