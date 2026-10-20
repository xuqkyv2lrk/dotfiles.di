#!/usr/bin/env bash
set -euo pipefail

if pgrep -x qs > /dev/null || pgrep -f "quickshell -p" > /dev/null || pgrep -x noctalia > /dev/null; then
    "${HOME}/.config/niri/scripts/noctalia_ctl.sh" call dock toggle
else
    pkill waybar
    waybar &
fi
