#!/usr/bin/env bash
set -euo pipefail

if pgrep -x qs > /dev/null; then
    qs ipc -p "${HOME}/.dotfiles.di/quickshell/noctalia-shell" call dock toggle
else
    pkill waybar
    waybar &
fi
