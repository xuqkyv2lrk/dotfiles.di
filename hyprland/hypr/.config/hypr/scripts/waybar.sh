#!/usr/bin/env bash

LOCKFILE="/tmp/waybar_restart.lock"

[[ -e "${LOCKFILE}" ]] && exit 1

touch "${LOCKFILE}"

# Find the internal monitor name (assumes it starts with "eDP")
internal_monitor=$(hyprctl monitors -j | jq -r '.[] | select(.name | startswith("eDP")) | .name')

# Exit if no internal monitor is found
if [[ -z "${internal_monitor}" ]]; then
    echo "No internal monitor found!"
    rm "${LOCKFILE}"
    exit 1
fi

# Get the external monitor name, if any
external_monitor=$(hyprctl monitors -j | jq -r ".[] | select(.name != \"${internal_monitor}\") | .name" | head -n1)

# Set output to external monitor if found, otherwise use eDP-1
output="${external_monitor:-$internal_monitor}"

# Update Waybar config
sed -i "s/\"output\": \[\"[^\"]*\"\]/\"output\": [\"${output}\"]/" "${HOME}/.config/waybar/config"

# Restart Waybar
killall waybar
waybar -b bar-0 &

active_workspace=$(hyprctl activewindow -j | jq -r '.workspace.name')

hyprctl keyword workspace 6,monitor:"${internal_monitor}"
hyprctl keyword workspace 6,monitor:DP-1
hyprctl keyword workspace 6,monitor:DP-2
hyprctl keyword workspace 6,monitor:HDMI-A-1

hyprctl keyword workspace 2,monitor:DP-1
hyprctl keyword workspace 2,monitor:DP-2
hyprctl keyword workspace 2,monitor:HDMI-A-1
hyprctl keyword workspace 2,monitor:"${internal_monitor}"

hyprctl dispatch workspace 6
hyprctl dispatch workspace 1
hyprctl dispatch workspace "${active_workspace}"

rm "${LOCKFILE}"
