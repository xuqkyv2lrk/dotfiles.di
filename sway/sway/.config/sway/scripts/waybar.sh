#!/usr/bin/env bash

# Get the external monitor name, if any
external_monitor="$(swaymsg -t get_outputs | jq -r '.[] | select(.active==true and .name!="eDP-1") | .name' | head -n1)"

# Set output to external monitor if found, otherwise use eDP-1
output="${external_monitor:-eDP-1}"

echo "Using output: ${output}"

# Update Waybar config
sed -i "s/\"output\": \[\"[^\"]*\"\]/\"output\": [\"${output}\"]/" "${HOME}/.config/waybar/config"

# Restart Waybar
killall waybar
waybar -b "${output}" &

active_workspace=$(swaymsg -t get_workspaces | jq -r '.[] | select(.focused==true).name')

swaymsg "workspace 6 output eDP-1 DP-1 DP-2 HDMI-A-1"
swaymsg "workspace 2 output DP-1 DP-2 HDMI-A-1 eDP-1"

swaymsg workspace 6
swaymsg workspace "${active_workspace}"
