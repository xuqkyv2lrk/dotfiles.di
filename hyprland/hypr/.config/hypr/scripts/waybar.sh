#!/usr/bin/env bash

LOCKFILE="/tmp/waybar_restart.lock"
STARTUPFLAG="/tmp/startup.flag"

[[ -e "${LOCKFILE}" ]] && exit 1

touch "${LOCKFILE}"

# Find the internal monitor name (assumes it starts with "eDP")
internal_monitor=$(hyprctl monitors -j | jq -r '.[] | select(.name | startswith("eDP")) | .name')

# Get the external monitor name, if any
external_monitor=$(hyprctl monitors -j | jq -r ".[] | select(.name != \"${internal_monitor}\") | .name" | head -n1)

# Set output to external monitor if found, otherwise use internal monitor
output="${external_monitor:-$internal_monitor}"

# Update Waybar config
sed -i "s/\"output\": \[\"[^\"]*\"\]/\"output\": [\"${output}\"]/" "${HOME}/.config/waybar/config"

# Restart Waybar
killall waybar
waybar -b bar-0 &

# Determine active workspace
if [[ ! -e "${STARTUPFLAG}" ]]; then
    active_workspace=1
    touch "${STARTUPFLAG}"
else
    active_workspace=$(hyprctl activewindow -j | jq -r '.workspace.name')
fi

# Move workspaces to external monitor except workspace 6
if [[ -n "${external_monitor}" ]]; then
    workspaces=$(hyprctl workspaces -j | jq -r '.[] | .name')
    for workspace in ${workspaces}; do
        if [[ "$workspace" != "6" ]]; then
            hyprctl dispatch moveworkspacetomonitor "$workspace" "$external_monitor"
        fi
    done
    
    # Ensure workspace 6 stays on the internal monitor
    hyprctl dispatch moveworkspacetomonitor 6 "$internal_monitor"
    
    # Dispatch to the active workspace
    hyprctl dispatch workspace "${active_workspace}"
fi

rm "${LOCKFILE}"
