#!/usr/bin/env bash

monitor_count=$(hyprctl monitors | grep -c "Monitor")
internal_monitor=$(hyprctl monitors -j | jq -r '.[] | select(.name | startswith("eDP")) | .name')
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}"

mkdir -p "${cache_dir}"

echo "${internal_monitor}" > "${cache_dir}/internal_monitor"
echo "closed" > "${cache_dir}/lid_state"

if [ "${monitor_count}" -gt 1 ]; then
    # Multiple monitors, just disable laptop screen
    hyprctl keyword monitor "${internal_monitor}, disable"
elif [ "${monitor_count}" -eq 1 ] && ! hyprctl monitors | grep -q "${internal_monitor}"; then
    # Only external monitor is active
    hyprctl keyword monitor "${internal_monitor}, disable"
else
    # Only laptop screen, lock then suspend
    hyprlock &
    sleep 0.5
    systemctl suspend
fi
