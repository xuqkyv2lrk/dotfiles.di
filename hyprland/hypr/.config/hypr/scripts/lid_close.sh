#!/usr/bin/env bash
set -euo pipefail

internal=$(hyprctl monitors -j | jq -r '.[] | select(.name | startswith("eDP")) | .name')
[[ -z "${internal}" ]] && exit 0

hyprctl keyword monitor "${internal}, disable"
