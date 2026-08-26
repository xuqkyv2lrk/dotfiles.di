#!/usr/bin/env bash

source "${HOME}/.config/sketchybar/colors.sh"
source "${HOME}/.config/sketchybar/icons.sh"

_battery_update() {
    local percentage charging icon color

    percentage="$(pmset -g batt | grep -oE '[0-9]+%' | head -1 | tr -d '%')"
    charging="$(pmset -g batt | grep -c 'AC Power' || true)"

    if [[ "${charging}" -gt 0 ]]; then
        icon="${ICON_BATTERY_CHARGING}"
        color="${HOVER}"
    elif [[ "${percentage:-0}" -ge 75 ]]; then
        icon="${ICON_BATTERY_100}"
        color="${HOVER}"
    elif [[ "${percentage:-0}" -ge 50 ]]; then
        icon="${ICON_BATTERY_75}"
        color="${LABEL_COLOR}"
    elif [[ "${percentage:-0}" -ge 25 ]]; then
        icon="${ICON_BATTERY_50}"
        color="${WARN_COLOR}"
    elif [[ "${percentage:-0}" -ge 10 ]]; then
        icon="${ICON_BATTERY_25}"
        color="${URGENT_COLOR}"
    else
        icon="${ICON_BATTERY_0}"
        color="${URGENT_COLOR}"
    fi

    sketchybar --set battery \
        icon="${icon}" \
        icon.color="${color}" \
        label="${percentage}%"
}

if [[ -n "${SENDER}" ]]; then
    _battery_update
else
    sketchybar --add item battery right \
               --set battery \
                   update_freq=60 \
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
                   script="${HOME}/.config/sketchybar/items/battery.sh" \
               --subscribe battery power_source_change system_woke
    _battery_update
fi
