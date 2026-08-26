#!/usr/bin/env bash

source "${HOME}/.config/sketchybar/colors.sh"
source "${HOME}/.config/sketchybar/icons.sh"

_wifi_update() {
    local ssid icon color

    ssid="$(networksetup -getairportnetwork en0 2>/dev/null | awk -F': ' '{print $2}')"

    if [[ -z "${ssid}" || "${ssid}" == "You are not associated with an AirPort network." ]]; then
        icon="${ICON_WIFI_OFF}"
        color="${URGENT_COLOR}"
        ssid="offline"
    else
        icon="${ICON_WIFI}"
        color="${ICON_COLOR}"
    fi

    sketchybar --set wifi \
        icon="${icon}" \
        icon.color="${color}" \
        label="${ssid}"
}

if [[ -n "${SENDER}" ]]; then
    _wifi_update
else
    sketchybar --add item wifi right \
               --set wifi \
                   update_freq=30 \
                   icon.font="JetBrainsMono Nerd Font:Regular:14.0" \
                   icon.color="${ICON_COLOR}" \
                   label.color="${LABEL_COLOR}" \
                   label.font="JetBrainsMono Nerd Font:Regular:12.0" \
                   background.color="${ITEM_BG_COLOR}" \
                   background.corner_radius=10 \
                   background.height=26 \
                   background.drawing=on \
                   padding_left=6 \
                   padding_right=6 \
                   script="${HOME}/.config/sketchybar/items/wifi.sh" \
               --subscribe wifi wifi_change
    _wifi_update
fi
