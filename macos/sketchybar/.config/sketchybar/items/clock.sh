#!/usr/bin/env bash

source "${HOME}/.config/sketchybar/colors.sh"
source "${HOME}/.config/sketchybar/icons.sh"

sketchybar --add item clock right \
           --set clock \
               update_freq=10 \
               icon="${ICON_CLOCK}" \
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
               script="sketchybar --set clock label=\"\$(date '+%a %d %b  %H:%M')\""
