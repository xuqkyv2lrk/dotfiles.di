#!/usr/bin/env bash

LOCKFILE="/tmp/waybar_restart.lock"

[[ -e "${LOCKFILE}" ]] && exit 1

touch "${LOCKFILE}"

# Get the external monitor name, if any
external_monitor="$(hyprctl monitors -j | jq -r '.[] | select(.name != "eDP-1") | .name' | head -n1)"

# Set output to external monitor if found, otherwise use eDP-1
output="${external_monitor:-eDP-1}"

echo "Using output: ${output}"

# Update Waybar config
sed -i "s/\"output\": \[\"[^\"]*\"\]/\"output\": [\"${output}\"]/" "${HOME}/.config/waybar/config"

# Restart Waybar
killall waybar
waybar -b bar-0 &

active_workspace=$(hyprctl activewindow -j | jq -r '.workspace.name')

hyprctl dispatch workspace 6
hyprctl dispatch workspace 1
hyprctl dispatch workspace "${active_workspace}"

# When laptop is closed and an external monitor is connected
# the laptop screen will become active, so this logic will turn it off
if grep -q closed /proc/acpi/button/lid/LID*/state; then
    if hyprctl monitors -j | jq -e '.[] | select(.name == "eDP-1" and .disabled == false)' > /dev/null; then
        hyprctl keyword monitor eDP-1,disable
    fi
fi

rm "${LOCKFILE}"
