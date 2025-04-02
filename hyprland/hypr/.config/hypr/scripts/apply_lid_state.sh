#!/usr/bin/env bash

cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}"
internal_monitor=$(cat "${cache_dir}/internal_monitor")
list_state=$(cat "${cache_dir}/lid_state" 2>/dev/null)

if [[ "${list_state}" == "closed" && -n "${internal_monitor}" ]]; then
  hyprctl keyword monitor "${internal_monitor}, disable"
fi
