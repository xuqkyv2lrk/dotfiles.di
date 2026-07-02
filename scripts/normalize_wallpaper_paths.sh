#!/usr/bin/env bash
set -euo pipefail

# Normalize absolute home paths back to ~ in noctalia wallpaper directory fields.
# Called by the noctalia wallpaperChange hook after each wallpaper selection.
sed -i "s|/home/[^/]*/\.dotfiles\.di/wallpapers|~/.dotfiles.di/wallpapers|g" \
    "${HOME}/.config/noctalia/settings.json"
