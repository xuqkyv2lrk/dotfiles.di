#!/usr/bin/env bash
set -euo pipefail

# Usage: wallpaper_cycle.sh
# Sets a random wallpaper on every screen, matched to the screen's resolution by filename.
# The native picker (noctalia msg panel-toggle wallpaper) is bound separately.

readonly WALLPAPER_DIR="${HOME}/.dotfiles.di/wallpapers"

function screen_resolution() {
    local screen="$1"
    niri msg -j outputs 2>/dev/null \
        | jq -r --arg s "${screen}" '.[$s] | .modes[.current_mode] | "\(.width)x\(.height)"'
}

function matching_wallpapers() {
    local screen="$1"
    local res
    res="$(screen_resolution "${screen}")"
    find "${WALLPAPER_DIR}" -maxdepth 1 -type f \( -iname "${res}_*.jpg" -o -iname "${res}_*.jpeg" -o -iname "${res}_*.png" -o -iname "${res}_*.webp" \)
}

function set_random() {
    local screen="$1"
    local wallpaper
    wallpaper="$(matching_wallpapers "${screen}" | shuf -n1)" || return 0
    [[ -z "${wallpaper}" ]] && return 0
    noctalia msg wallpaper-set "${screen}" "${wallpaper}"
}

function connected_screens() {
    niri msg -j outputs 2>/dev/null \
        | jq -r 'to_entries[] | select(.value.current_mode != null) | .key'
}

function main() {
    local screen

    while IFS= read -r screen; do
        set_random "${screen}"
    done < <(connected_screens)
}

main "$@"
