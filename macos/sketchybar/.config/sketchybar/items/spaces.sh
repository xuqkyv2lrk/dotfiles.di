#!/usr/bin/env bash
# Registers workspace indicator items for Aerospace workspaces 1–9.

source "${HOME}/.config/sketchybar/colors.sh"

PLUGIN_DIR="${HOME}/.config/sketchybar/plugins"

sketchybar --add event aerospace_workspace_change

for i in 1 2 3 4 5 6 7 8 9; do
    sketchybar --add item "space.${i}" left \
               --set "space.${i}" \
                   icon="${i}" \
                   icon.font="JetBrainsMono Nerd Font:Bold:12.0" \
                   icon.color="${MUTED_COLOR}" \
                   icon.padding_left=6 \
                   icon.padding_right=6 \
                   label.drawing=off \
                   background.color="${SURFACE_VARIANT}" \
                   background.corner_radius=10 \
                   background.height=26 \
                   background.drawing=off \
                   click_script="aerospace workspace ${i}" \
                   script="${PLUGIN_DIR}/space.sh" \
               --subscribe "space.${i}" aerospace_workspace_change
done

sketchybar --add item spaces_separator left \
           --set spaces_separator \
               icon="│" \
               icon.font="JetBrainsMono Nerd Font:Regular:14.0" \
               icon.color="${INACTIVE}" \
               icon.padding_left=2 \
               icon.padding_right=2 \
               label.drawing=off \
               background.drawing=off
