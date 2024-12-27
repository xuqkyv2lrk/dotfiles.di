#!/usr/bin/env bash

action="${1}"
internal_display=$(swaymsg -t get_outputs | jq -r '.[] | select(.name | startswith("eDP")) | .name')
has_external_display=$(swaymsg -t get_outputs | jq -e '.[] | select(.name | startswith("eDP") | not) | .active == true')

if [[ "${has_external_display}" == true ]]; then
    swaymsg output "${internal_display}" "${action}"
fi
