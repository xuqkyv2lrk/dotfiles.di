#!/usr/bin/env bash

source "${HOME}/.config/sketchybar/colors.sh"
source "${HOME}/.config/sketchybar/icons.sh"

PLUGIN_DIR="${HOME}/.config/sketchybar/plugins"

sketchybar --add item cpu right \
           --set cpu \
               update_freq=5 \
               script="${PLUGIN_DIR}/resources.sh" \
               icon="${ICON_CPU}" \
               icon.font="JetBrainsMono Nerd Font:Regular:14.0" \
               icon.color="${ICON_COLOR}" \
               label="--" \
               label.color="${LABEL_COLOR}" \
               label.font="JetBrainsMono Nerd Font:Regular:12.0" \
               background.color="${ITEM_BG_COLOR}" \
               background.corner_radius=10 \
               background.height=26 \
               background.drawing=on \
               padding_left=6 \
               padding_right=6

sketchybar --add item temp right \
           --set temp \
               icon="${ICON_TEMP}" \
               icon.font="JetBrainsMono Nerd Font:Regular:14.0" \
               icon.color="${ICON_COLOR}" \
               label="--" \
               label.color="${LABEL_COLOR}" \
               label.font="JetBrainsMono Nerd Font:Regular:12.0" \
               background.color="${ITEM_BG_COLOR}" \
               background.corner_radius=10 \
               background.height=26 \
               background.drawing=on \
               padding_left=6 \
               padding_right=6

sketchybar --add item mem right \
           --set mem \
               icon="${ICON_MEM}" \
               icon.font="JetBrainsMono Nerd Font:Regular:14.0" \
               icon.color="${ICON_COLOR}" \
               label="--" \
               label.color="${LABEL_COLOR}" \
               label.font="JetBrainsMono Nerd Font:Regular:12.0" \
               background.color="${ITEM_BG_COLOR}" \
               background.corner_radius=10 \
               background.height=26 \
               background.drawing=on \
               padding_left=6 \
               padding_right=6
