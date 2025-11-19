#!/usr/bin/env bash

# Give lid_open.sh time to update cache if needed
sleep 0.3

cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}"
internal_monitor=$(cat "${cache_dir}/internal_monitor" 2>/dev/null)

cached_lid_state=$(cat "${cache_dir}/lid_state" 2>/dev/null)

# If cache says open, we're good
if [[ "${cached_lid_state}" == "open" ]]; then
    exit 0
fi

# Double check with actual hardware state
actual_lid_state=$(grep -q "closed" /proc/acpi/button/lid/*/state && echo "closed" || echo "open")

if [[ "${actual_lid_state}" == "closed" && -n "${internal_monitor}" ]]; then
  hyprctl keyword monitor "${internal_monitor}, disable"
fi
