#!/usr/bin/env bash
set -euo pipefail

if pgrep -x qs > /dev/null; then
    qs ipc -p "${HOME}/.dotfiles.di/quickshell/noctalia-shell" call sessionMenu toggle
else
    "${XDG_CONFIG_HOME}/sway/scripts/power_menu.sh"
fi
