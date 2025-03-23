#!/usr/bin/env bash

# Find the internal monitor name (assumes it starts with "eDP")
internalMonitor=$(hyprctl monitors -j | jq -r '.[] | select(.name | startswith("eDP")) | .name')

# Exit if no internal monitor is found
if [[ -z "${internalMonitor}" ]]; then
    echo "No internal monitor found!"
    exit 1
fi

# Enable the internal monitor
if [ "${internalMonitor}" = "eDP-3" ]; then
    hyprctl keyword monitor "${internalMonitor}, preferred, auto, 1.6"
else
    hyprctl keyword monitor "${internalMonitor}, preferred, auto, auto"
fi
