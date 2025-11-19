#!/usr/bin/env bash

set -euo pipefail

# Show networks - with custom app-id for positioning
selected=$(nmcli -f SSID,SIGNAL,SECURITY device wifi list | \
    awk 'NR>1 && $1 != "" && $1 != "--" {
        ssid = $1
        signal = $2
        security = $3
        
        if (!(ssid in seen) || signal > max_signal[ssid]) {
            seen[ssid] = 1
            max_signal[ssid] = signal
            sec[ssid] = security
        }
    }
    END {
        n = asorti(max_signal, sorted_ssids, "@val_num_desc")
        for (i = 1; i <= n; i++) {
            ssid = sorted_ssids[i]
            signal = max_signal[ssid]
            
            if (signal >= 75) icon = "󰤨"
            else if (signal >= 50) icon = "󰤥"
            else if (signal >= 25) icon = "󰤢"
            else icon = "󰤟"
            
            security_icon = (sec[ssid] == "--") ? "" : "󰌾"
            printf "%s  %s %s\n", icon, ssid, security_icon
        }
    }' | \
    fuzzel --dmenu --name fuzzel-network --prompt='󰖩  ' --width=28 --lines=8 --font='JetBrains Mono:size=11' --horizontal-pad=16 --vertical-pad=12 --inner-pad=6 --border-width=2 --border-radius=12 --anchor=top-right --x-margin=10 --y-margin=9)

# Extract SSID
ssid=$(echo "${selected}" | awk '{print $2}')

if [ -n "${ssid}" ]; then
    # Check if network has security
    has_lock=$(echo "${selected}" | grep -q "󰌾" && echo "yes" || echo "no")
    
    if [ "${has_lock}" = "yes" ]; then
        # Password prompt - also with custom app-id
        password=$(echo "" | fuzzel --dmenu --name fuzzel-network --prompt="󰌾 Password: " --width=28 --lines=1 --font='JetBrains Mono:size=11' --horizontal-pad=16 --vertical-pad=12 --inner-pad=6 --border-width=2 --border-radius=12 --password --anchor=top-right --x-margin=10 --y-margin=9)
        
        if [ -n "${password}" ]; then
            notify-send -u normal -i network-wireless "WiFi" "Connecting to ${ssid}..." &
            sleep 0.5
            
            if nmcli device wifi connect "${ssid}" password "${password}" 2>&1; then
                notify-send -u normal -i network-wireless "WiFi" "Connected to ${ssid}" &
            else
                notify-send -u critical -i network-wireless-offline "WiFi" "Failed to connect to ${ssid}" &
            fi
        fi
    else
        # Open network, no password needed
        notify-send -u normal -i network-wireless "WiFi" "Connecting to ${ssid}..." &
        sleep 0.5
        
        if nmcli device wifi connect "${ssid}" 2>&1; then
            notify-send -u normal -i network-wireless "WiFi" "Connected to ${ssid}" &
        else
            notify-send -u critical -i network-wireless-offline "WiFi" "Failed to connect to ${ssid}" &
        fi
    fi
fi
