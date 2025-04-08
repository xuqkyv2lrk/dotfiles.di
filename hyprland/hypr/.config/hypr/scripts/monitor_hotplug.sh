#!/usr/bin/env bash

hotplug_event() {
    "${XDG_CONFIG_HOME}/hypr/scripts/waybar.sh"
}

socat - UNIX-CONNECT:"${XDG_RUNTIME_DIR}"/hypr/"${HYPRLAND_INSTANCE_SIGNATURE}"/.socket2.sock | while read -r line; do
    case ${line%>>*} in
        monitoradded*|monitorremoved*)
            hotplug_event
            ;;
    esac
done
