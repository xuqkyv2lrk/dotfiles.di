#!/usr/bin/env bash

monitor_count=$(hyprctl monitors | grep -c "Monitor")
# Find the internal monitor name (assumes it starts with "eDP")
internal_monitor=$(hyprctl monitors -j | jq -r '.[] | select(.name | startswith("eDP")) | .name')
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}"

# Create the cache directory if it doesn't exist
mkdir -p "${cache_dir}"

# Cache the internal monitor name
echo "${internal_monitor}" > "${cache_dir}/internal_monitor"
echo "closed" > "${cache_dir}/lid_state"

# Check if more than one monitor is active
if [ "${monitor_count}" -gt 1 ]; then
    # Multiple monitors active, just disable the laptop screen
    hyprctl keyword monitor "${internal_monitor}, disable"
elif [ "${monitor_count}" -eq 1 ] && ! hyprctl monitors | grep -q "${internal_monitor}"; then
     # Only one monitor active and it's not the internal one
    hyprctl keyword monitor "${internal_monitor}, disable"
else
    # Only laptop screen active, lock and suspend
    hyprlock
    systemctl suspend
fi
