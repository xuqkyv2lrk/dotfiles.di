#!/usr/bin/env bash
set -euo pipefail

if pgrep -x qs > /dev/null; then
    qs ipc -p "${HOME}/.dotfiles.di/quickshell/noctalia-shell" call notifications toggleHistory
else
    swaync-client -t -sw
fi
