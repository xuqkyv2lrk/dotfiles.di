#!/usr/bin/env bash

# Determine the cache directory
if [ -n "${XDG_CACHE_HOME}" ]; then
    cacheDir="${XDG_CACHE_HOME}"
else
    cacheDir="${HOME}/.cache"
fi

internalMonitor=$(cat "${cacheDir}/internal_monitor")

# Exit if no internal monitor is cached
if [[ -z "${internalMonitor}" ]]; then
    # Fallback to finding the internal monitor if cache is empty
    internalMonitor=$(hyprctl monitors -j | jq -r '.[] | select(.name | startswith("eDP")) | .name')

    if [[ -z "${internalMonitor}" ]]; then
        echo "No internal monitor found!"
        exit 1
    fi
fi

# Enable the internal monitor
if [ "${internalMonitor}" = "eDP-2" ]; then
    hyprctl keyword monitor "${internalMonitor}, preferred, auto, 1.6"
else
    hyprctl keyword monitor "${internalMonitor}, preferred, auto, auto"
fi

# Remove the cache file after use
rm "${cacheDir}/internal_monitor"
