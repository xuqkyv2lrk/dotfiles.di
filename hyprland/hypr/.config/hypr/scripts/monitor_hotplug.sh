#!/usr/bin/env bash

readonly LOCKFILE="/tmp/monitor_layout.lock"
readonly STARTUPFLAG="/tmp/startup.flag"

function handle_monitor_change() {
    [[ -e "${LOCKFILE}" ]] && return
    touch "${LOCKFILE}"

    local internal_monitor external_monitor output active_workspace workspaces workspace
    internal_monitor="$(hyprctl monitors -j | jq -r '.[] | select(.name | startswith("eDP")) | .name')"
    external_monitor="$(hyprctl monitors -j | jq -r ".[] | select(.name != \"${internal_monitor}\") | .name" | head -n1)"
    output="${external_monitor:-$internal_monitor}"

    if [[ ! -e "${STARTUPFLAG}" ]]; then
        active_workspace=1
        touch "${STARTUPFLAG}"
    else
        active_workspace="$(hyprctl activewindow -j | jq -r '.workspace.name')"
    fi

    if [[ -n "${external_monitor}" ]]; then
        workspaces="$(hyprctl workspaces -j | jq -r '.[] | .name')"
        for workspace in ${workspaces}; do
            if [[ "${workspace}" != "6" ]]; then
                hyprctl dispatch moveworkspacetomonitor "${workspace}" "${external_monitor}"
            fi
        done
        hyprctl dispatch moveworkspacetomonitor 6 "${internal_monitor}"
        hyprctl dispatch workspace "${active_workspace}"
    fi

    rm "${LOCKFILE}"
}

socat - UNIX-CONNECT:"${XDG_RUNTIME_DIR}"/hypr/"${HYPRLAND_INSTANCE_SIGNATURE}"/.socket2.sock | while read -r line; do
    case ${line%>>*} in
        monitoradded*|monitorremoved*)
            handle_monitor_change
            ;;
    esac
done
