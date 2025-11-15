#!/usr/bin/env bash

cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}"

# Update cache immediately to avoid race condition
echo "open" > "${cache_dir}/lid_state"

actual_lid_state=$(grep -q "closed" /proc/acpi/button/lid/*/state && echo "closed" || echo "open")
echo "${actual_lid_state}" > "${cache_dir}/lid_state"

internal_monitor=$(cat "${cache_dir}/internal_monitor" 2>/dev/null)

if [[ -z "${internal_monitor}" ]]; then
    internal_monitor=$(hyprctl monitors -j | jq -r '.[] | select(.name | startswith("eDP")) | .name')

    if [[ -z "${internal_monitor}" ]]; then
        echo "No internal monitor found!"
        exit 1
    fi
    
    echo "${internal_monitor}" > "${cache_dir}/internal_monitor"
fi

# Re-enable the monitor
if [ "${internal_monitor}" = "eDP-2" ]; then
    hyprctl keyword monitor "${internal_monitor}, preferred, auto, 1.6"
else
    hyprctl keyword monitor "${internal_monitor}, preferred, auto, auto"
fi

# Reset hypridle timers
pkill -USR1 hypridle
