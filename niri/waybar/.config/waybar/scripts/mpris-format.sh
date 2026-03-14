#!/usr/bin/env bash
set -euo pipefail

status=$(playerctl status 2>/dev/null) || { echo '{"text":""}'; exit 0; }

if [[ "$status" == "Stopped" || -z "$status" ]]; then
    echo '{"text":""}'
    exit 0
fi

artist=$(playerctl metadata artist 2>/dev/null || echo "")
title=$(playerctl metadata title 2>/dev/null | sed 's/^[▶⏸] //' || echo "")

if [[ -z "$title" ]]; then
    echo '{"text":""}'
    exit 0
fi

if [[ -n "$artist" ]]; then
    text="${artist} // ${title}"
else
    text="${title}"
fi

text="$(echo "${text}" | sed 's/\\/\\\\/g; s/"/\\"/g')"
printf '{"text":"%s"}\n' "${text}"
