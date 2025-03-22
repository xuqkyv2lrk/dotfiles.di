#!/usr/bin/env bash

options="Suspend\nRestart\nShutdown"

selected=$(echo -e "${options}" | BEMENU_BACKEND=wayland bemenu --single-instance --bottom -nif -p "⏻ Menu:" -l 10 -R 5 -B 1px --bdr "#cba6f7" --line-height 24 --fixed-height --margin 5px --fn "JetBrainsMono Nerd Font 12" --fb "#1e1e2eE6" --ff "#cdd6f4" --nb "#1e1e2eE6" --nf "#cdd6f4" --tb "#1e1e2eE6" --hb "#1e1e2eE6" --tf "#f38ba8" --hf "#f9e2af" --af "#cdd6f4" --ab "#1e1e2eE6")

case "${selected}" in
    Suspend)
        exec systemctl suspend
        ;;
    Restart)
        exec systemctl reboot
        ;;
    Shutdown)
        exec systemctl poweroff
        ;;
esac

