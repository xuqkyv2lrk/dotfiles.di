#!/usr/bin/env bash
set -euo pipefail

internal=$(hyprctl monitors -j | jq -r '.[] | select(.name | startswith("eDP")) | .name')
[[ -z "${internal}" ]] && exit 0

if [[ "${internal}" == "eDP-2" ]]; then
    hyprctl keyword monitor "${internal}, preferred, auto, 1.6"
else
    hyprctl keyword monitor "${internal}, preferred, auto, auto"
fi
