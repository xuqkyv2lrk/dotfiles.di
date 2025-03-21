#!/usr/bin/env bash

monitorCount=$(hyprctl monitors | grep -c "Monitor")
internalMonitor="eDP-1"

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
