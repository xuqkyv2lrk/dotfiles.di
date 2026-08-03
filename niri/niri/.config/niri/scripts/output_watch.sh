#!/usr/bin/env bash
set -euo pipefail

readonly SCRIPT_DIR="$(dirname "$(realpath "$0")")"

function main() {
    while true; do
        niri msg event-stream 2>/dev/null | while IFS= read -r line; do
            if [[ "${line}" == *"OutputsChanged"* ]]; then
                "${SCRIPT_DIR}/layout_profile.sh" || true
            fi
        done || true
        sleep 1
    done
}

main "$@"
