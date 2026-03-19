#!/usr/bin/env bash
set -euo pipefail

# Restart waybar after sleep only if Noctalia (quickshell) is not running.
# Noctalia manages its own bar and does not need to be restarted after resume.
pgrep -x qs > /dev/null || waybar &
