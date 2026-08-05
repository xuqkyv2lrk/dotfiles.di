#!/usr/bin/env bash
set -euo pipefail

readonly LOCAL_CONFIG="${HOME}/.config/niri/local.kdl"

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

    local current=""
    if [[ -f "${LOCAL_CONFIG}" ]]; then
        current="$(grep -o 'proportion [0-9.]*' "${LOCAL_CONFIG}" | grep -o '[0-9.]*$' || true)"
    fi

    if [[ "${current}" == "${proportion}" ]]; then
        exit 0
    fi

    printf 'layout {\n    default-column-width { proportion %s; }\n}\n' "${proportion}" > "${LOCAL_CONFIG}"
    niri msg action load-config-file
}

main "$@"
