#!/usr/bin/env bash

cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}"
lid_state=$(grep -q "closed" /proc/acpi/button/lid/*/state && echo "closed" || echo "open")
internal_monitor=$(hyprctl monitors -j | jq -r '.[] | select(.name | test("eDP|LVDS")) | .name')

# Create the cache directory if it doesn't exist
mkdir -p "${cache_dir}"

# Cache the lid state and internal monitor name
echo "${lid_state}" > "${cache_dir}/lid_state"
[[ -n "${internal_monitor}" ]] && echo "${internal_monitor}" > "${cache_dir}/internal_monitor"
