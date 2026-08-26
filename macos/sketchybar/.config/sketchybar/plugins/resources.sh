#!/usr/bin/env bash
# Triggered by cpu item every 5s; updates cpu, temp, and mem in one macmon call.

source "${HOME}/.config/sketchybar/colors.sh"

if ! command -v macmon >/dev/null 2>&1; then
    sketchybar --set cpu label="N/A" --set temp label="N/A" --set mem label="N/A"
    exit 0
fi

json="$(macmon pipe -s 1 2>/dev/null)"
[[ -z "${json}" ]] && exit 0

read -r cpu_pct cpu_temp ram_used <<< "$(printf '%s' "${json}" | jq -r '[
    (.cpu_active_ratio * 100 | round | tostring),
    (.temp.cpu_temp_avg | round | tostring),
    ((.memory.ram_usage / 1073741824 * 10 | round) / 10 | tostring)
] | join(" ")')"

if [[ "${cpu_pct}" -ge 80 ]]; then
    cpu_color="${URGENT_COLOR}"
elif [[ "${cpu_pct}" -ge 50 ]]; then
    cpu_color="${WARN_COLOR}"
else
    cpu_color="${ICON_COLOR}"
fi

if [[ "${cpu_temp}" -ge 90 ]]; then
    temp_color="${URGENT_COLOR}"
elif [[ "${cpu_temp}" -ge 70 ]]; then
    temp_color="${WARN_COLOR}"
else
    temp_color="${ICON_COLOR}"
fi

sketchybar \
    --set cpu  icon.color="${cpu_color}"  label="${cpu_pct}%" \
    --set temp icon.color="${temp_color}" label="${cpu_temp}°" \
    --set mem  label="${ram_used}G"
