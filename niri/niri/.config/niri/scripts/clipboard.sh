#!/usr/bin/env bash
set -euo pipefail

if pgrep -x qs > /dev/null; then
    qs ipc -p "${HOME}/.dotfiles.di/quickshell/noctalia-shell" call launcher clipboard
else
    cliphist list | fuzzel -d | cliphist decode | wl-copy
fi
