#!/usr/bin/env bash

cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}"
internal_monitor=$(cat "${cache_dir}/internal_monitor")

# Exit if no internal monitor is cached
if [[ -z "${internal_monitor}" ]]; then
    # Fallback to finding the internal monitor if cache is empty
    internal_monitor=$(hyprctl monitors -j | jq -r '.[] | select(.name | startswith("eDP")) | .name')

    if [[ -z "${internal_monitor}" ]]; then
        echo "No internal monitor found!"
        exit 1
    fi
fi

# Enable the internal monitor
if [ "${internal_monitor}" = "eDP-2" ]; then
    hyprctl keyword monitor "${internal_monitor}, preferred, auto, 1.6"
else
    hyprctl keyword monitor "${internal_monitor}, preferred, auto, auto"
fi

# Clear cached lid state
rm -f "${cache_dir}/lid_state"
