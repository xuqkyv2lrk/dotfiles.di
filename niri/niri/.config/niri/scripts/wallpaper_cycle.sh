#!/usr/bin/env bash
set -euo pipefail

# Usage: wallpaper_cycle.sh [--pick]
#   (no args)  random wallpaper per screen, matched to screen resolution
#   --pick     fuzzel picker per screen, filtered to matching resolution

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
    qs ipc -p "${HOME}/.dotfiles.di/quickshell/noctalia-shell" call wallpaper set "${wallpaper}" "${screen}"
}

function pick_wallpaper() {
    local screen="$1"
    local filename display selection

    declare -A name_to_file
    while IFS= read -r filepath; do
        filename="$(basename "${filepath}")"
        display="$(echo "${filename}" | sed 's/^[0-9]*x[0-9]*_//; s/\.[^.]*$//; s/_/ /g')"
        name_to_file["${display}"]="${filename}"
    done < <(matching_wallpapers "${screen}")

    selection="$(printf '%s\n' "${!name_to_file[@]}" | sort \
        | fuzzel --dmenu --prompt "${screen}: " 2>/dev/null)" || return 0
    [[ -z "${selection}" ]] && return 0

    qs ipc -p "${HOME}/.dotfiles.di/quickshell/noctalia-shell" call wallpaper set \
        "${WALLPAPER_DIR}/${name_to_file["${selection}"]}" "${screen}"
}

function connected_screens() {
    niri msg -j outputs 2>/dev/null \
        | jq -r 'to_entries[] | select(.value.current_mode != null) | .key'
}

function main() {
    local mode="${1:---random}"
    local screen

    while IFS= read -r screen; do
        case "${mode}" in
            --pick) pick_wallpaper "${screen}" ;;
            *)      set_random "${screen}" ;;
        esac
    done < <(connected_screens)
}

main "$@"
