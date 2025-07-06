#!/usr/bin/env bash

WALLPAPER_DIR="${XDG_CONFIG_HOME}/niri/wallpapers"
STATE_FILE="${HOME}/.cache/swww-current"
IMAGES=("${WALLPAPER_DIR}"/*)

if [[ -f "${STATE_FILE}" ]]; then
    IDX=$(cat "${STATE_FILE}")
else
    IDX=0
fi

IDX=$(( (IDX + 1) % ${#IMAGES[@]} ))
echo "${IDX}" > "${STATE_FILE}"

swww img "${IMAGES[${IDX}]}" --transition-type outer --transition-pos 1,1 --transition-duration 1 --transition-fps 120
