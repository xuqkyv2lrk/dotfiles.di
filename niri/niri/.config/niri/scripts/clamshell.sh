#!/usr/bin/env bash
set -euo pipefail

# Clamshell mode: disable eDP-1 when lid is closed, re-enable when opened.
# Runs as a systemd user service after niri starts.

readonly LID_STATE_FILE="/proc/acpi/button/lid/LID0/state"
readonly POLL_INTERVAL=2

function get_niri_socket() {
    ls /run/user/1000/niri.wayland-*.sock 2>/dev/null | head -1
}

function get_lid_state() {
    grep -o 'open\|closed' "${LID_STATE_FILE}" 2>/dev/null || printf 'open'
}

function apply_clamshell() {
    local socket="$1"
    local lid_state="$2"

    if [[ "${lid_state}" == "closed" ]]; then
        NIRI_SOCKET="${socket}" niri msg output eDP-1 off 2>/dev/null || true
    else
        NIRI_SOCKET="${socket}" niri msg output eDP-1 on 2>/dev/null || true
    fi
}

prev_lid=""

while true; do
    socket="$(get_niri_socket)"
    if [[ -n "${socket}" ]]; then
        lid="$(get_lid_state)"
        if [[ "${lid}" != "${prev_lid}" ]]; then
            prev_lid="${lid}"
            apply_clamshell "${socket}" "${lid}"
        fi
    fi
    sleep "${POLL_INTERVAL}"
done
