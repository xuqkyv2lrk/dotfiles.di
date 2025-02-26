#!/usr/bin/env bash

LOCKFILE="/tmp/waybar_restart.lock"

[[ -e "${LOCKFILE}" ]] && exit 1

touch "${LOCKFILE}"

# Get the external monitor name, if any
external_monitor="$(hyprctl monitors -j | jq -r '.[] | select(.name != "eDP-1") | .name' | head -n1)"

# Set output to external monitor if found, otherwise use eDP-1
output="${external_monitor:-eDP-1}"

# Update Waybar config
sed -i "s/\"output\": \[\"[^\"]*\"\]/\"output\": [\"${output}\"]/" "${HOME}/.config/waybar/config"

# Restart Waybar
killall waybar
waybar -b bar-0 &

active_workspace=$(hyprctl activewindow -j | jq -r '.workspace.name')

hyprctl keyword workspace 6,monitor:eDP-1
hyprctl keyword workspace 6,monitor:DP-1
hyprctl keyword workspace 6,monitor:DP-2
hyprctl keyword workspace 6,monitor:HDMI-A-1

hyprctl keyword workspace 2,monitor:DP-1
hyprctl keyword workspace 2,monitor:DP-2
hyprctl keyword workspace 2,monitor:HDMI-A-1
hyprctl keyword workspace 2,monitor:eDP-1

hyprctl dispatch workspace 1
hyprctl dispatch workspace 6
hyprctl dispatch workspace "${active_workspace}"

rm "${LOCKFILE}"
