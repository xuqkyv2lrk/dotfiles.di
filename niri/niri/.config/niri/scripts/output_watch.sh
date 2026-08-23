#!/usr/bin/env bash
set -euo pipefail

readonly SCRIPT_DIR="$(dirname "$(realpath "$0")")"
readonly RESUME_FLAG="/tmp/niri_just_resumed"

function connected_outputs() {
    niri msg -j outputs 2>/dev/null \
        | jq -r 'to_entries[] | select(.value.current_mode != null) | .key' \
        | sort | tr '\n' ','
}

function main() {
    local prev_outputs
    prev_outputs="$(connected_outputs)"
    local current_outputs

    while true; do
        while IFS= read -r line; do
            if [[ "${line}" == *"Workspaces changed"* ]]; then
                current_outputs="$(connected_outputs)"
                if [[ "${current_outputs}" != "${prev_outputs}" ]]; then
                    prev_outputs="${current_outputs}"
                    sleep 1
                    "${SCRIPT_DIR}/layout_profile.sh" || true
                    if [[ -f "${RESUME_FLAG}" ]]; then
                        rm -f "${RESUME_FLAG}"
                    else
                        "${SCRIPT_DIR}/wallpaper_cycle.sh" || true
                    fi
                fi
            fi
        done < <(niri msg event-stream 2>/dev/null) || true
        sleep 1
    done
}

main "$@"
