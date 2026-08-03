#!/usr/bin/env bash
set -euo pipefail

readonly CONFIG_FILE="${HOME}/.config/niri/config.kdl"

function is_ultrawide_active() {
    niri msg -j outputs 2>/dev/null \
        | jq -e 'to_entries | any(.[]; .value.current_mode != null and .value.modes[.value.current_mode].width >= 5000)' \
        > /dev/null 2>&1
}

function main() {
    local proportion

    if is_ultrawide_active; then
        proportion="0.33333"
    else
        proportion="0.5"
    fi

    local current
    current="$(grep '// dynamic' "${CONFIG_FILE}" | grep -o 'proportion [0-9.]*' | grep -o '[0-9.]*$')"

    if [[ "${current}" == "${proportion}" ]]; then
        exit 0
    fi

    sed -i "s/default-column-width { proportion [0-9.]*; } \/\/ dynamic/default-column-width { proportion ${proportion}; } \/\/ dynamic/" "${CONFIG_FILE}"
    niri msg action load-config-file
}

main "$@"
