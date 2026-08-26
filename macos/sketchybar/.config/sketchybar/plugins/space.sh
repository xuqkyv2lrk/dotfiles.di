#!/usr/bin/env bash
# Per-space event handler — runs once per space item on workspace focus change.
# $NAME: item name (e.g. "space.2"), $FOCUSED_WORKSPACE: set by aerospace trigger.

source "${HOME}/.config/sketchybar/colors.sh"

workspace="${NAME#space.}"
window_count="$(aerospace list-windows --workspace "${workspace}" 2>/dev/null | wc -l | tr -d ' ')"

if [[ "${workspace}" == "${FOCUSED_WORKSPACE}" ]]; then
    sketchybar --set "${NAME}" \
        icon="${workspace}" \
        icon.font="JetBrainsMono Nerd Font:Bold:12.0" \
        icon.color="${ON_ACCENT}" \
        icon.padding_left=10 \
        icon.padding_right=10 \
        background.color="${ACCENT}" \
        background.corner_radius=10 \
        background.drawing=on
elif [[ "${window_count}" -gt 0 ]]; then
    sketchybar --set "${NAME}" \
        icon="●" \
        icon.font="JetBrainsMono Nerd Font:Regular:7.0" \
        icon.color="${MUTED_COLOR}" \
        icon.padding_left=6 \
        icon.padding_right=6 \
        background.drawing=off
else
    sketchybar --set "${NAME}" \
        background.drawing=off \
        icon="●" \
        icon.font="JetBrainsMono Nerd Font:Regular:5.0" \
        icon.color="${INACTIVE}" \
        icon.padding_left=4 \
        icon.padding_right=4
fi
