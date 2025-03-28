#!/usr/bin/env bash

monitorCount=$(hyprctl monitors | grep -c "Monitor")

# Find the internal monitor name (assumes it starts with "eDP")
internalMonitor=$(hyprctl monitors -j | jq -r '.[] | select(.name | startswith("eDP")) | .name')

# Exit if no internal monitor is found
if [[ -z "${internalMonitor}" ]]; then
    echo "No internal monitor found!"
    exit 1
fi

if [ -n "${XDG_CACHE_HOME}" ]; then
    cacheDir="${XDG_CACHE_HOME}"
else
    cacheDir="${HOME}/.cache"
fi

# Create the cache directory if it doesn't exist
mkdir -p "${cacheDir}"

# Cache the internal monitor name
echo "${internalMonitor}" > "${cacheDir}/internal_monitor"

# Check if more than one monitor is active
if [ "${monitorCount}" -gt 1 ]; then
    # Multiple monitors active, just disable the laptop screen
    hyprctl keyword monitor "${internalMonitor}, disable"
elif [ "${monitorCount}" -eq 1 ] && ! hyprctl monitors | grep -q "${internalMonitor}"; then
     # Only one monitor active and it's not the internal one
    hyprctl keyword monitor "${internalMonitor}, disable"
else
    # Only laptop screen active, lock and suspend
    hyprlock
    systemctl suspend
fi
