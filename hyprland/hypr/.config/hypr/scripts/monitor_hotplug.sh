#!/usr/bin/env bash

hotplug_event() {
    swww img "${XDG_CONFIG_HOME}/hypr/wallpapers/alley.png" --transition-type=fade --transition-duration=0.7
    "${XDG_CONFIG_HOME}/hypr/scripts/waybar.sh"
}

socat - UNIX-CONNECT:"${XDG_RUNTIME_DIR}"/hypr/"${HYPRLAND_INSTANCE_SIGNATURE}"/.socket2.sock | while read -r line; do
    case ${line%>>*} in
        monitoradded*)
            hotplug_event
            ;;
        monitorremoved*)
            hotplug_event
            ;;
    esac
done
