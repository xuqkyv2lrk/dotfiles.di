#!/usr/bin/env bash
set -euo pipefail

if pgrep -f "noctalia-shell" > /dev/null || pgrep -x noctalia > /dev/null; then
    "${HOME}/.config/niri/scripts/noctalia_ctl.sh" call launcher clipboard
else
    cliphist list | fuzzel -d | cliphist decode | wl-copy
fi
