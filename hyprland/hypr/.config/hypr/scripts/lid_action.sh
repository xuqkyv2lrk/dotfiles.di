#!/usr/bin/env bash

# Check if more than one monitor is active
if [ "$(hyprctl monitors | grep -c "Monitor")" -gt 1 ]; then
    # Multiple monitors active, just disable the laptop screen
    hyprctl keyword monitor "eDP-1, disable"
else
    # Only laptop screen active, lock and suspend
    hyprlock
    systemctl suspend
fi
