#!/usr/bin/env bash
set -euo pipefail

readonly LOCAL_CONFIG="${HOME}/.config/niri/local.kdl"

function get_proportion() {
    local is_uw
    is_uw="$(niri msg -j outputs 2>/dev/null \
        | jq 'to_entries | any(.[];
            .value.current_mode != null and
            (.value.modes[.value.current_mode].width /
             .value.modes[.value.current_mode].height) > 2.0
        )')"

    if [[ "${is_uw}" == "true" ]]; then
        printf "0.33333"
    else
        printf "0.5"
    fi
}

function main() {
    local proportion
    proportion="$(get_proportion)"

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
