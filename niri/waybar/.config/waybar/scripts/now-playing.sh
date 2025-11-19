#!/bin/bash

VISIBLE_MIN=15
SCROLL_FILE="$HOME/.cache/nowplaying_scroll_pos"
MEDIA_FILE="$HOME/.cache/nowplaying_last_track"
PAUSE_CYCLES=4  # Number of cycles to pause at end (4 * 0.5s = 2s)
PAUSE_FILE="$HOME/.cache/nowplaying_pause_count"

# Fetch info
player_status=$(playerctl status 2>/dev/null)
if [[ $? -ne 0 || -z "$player_status" ]]; then
    rm -f "$SCROLL_FILE" "$MEDIA_FILE" "$PAUSE_FILE"
    exit 0
fi

artist=$(playerctl metadata xesam:artist 2>/dev/null)
title=$(playerctl metadata xesam:title 2>/dev/null)

if [[ -z "$artist" && -z "$title" ]]; then
    exit 0
fi

track="$title • $artist • "

# Reset scroll if new track
last_track=$(cat "$MEDIA_FILE" 2>/dev/null)
if [[ "$track" != "$last_track" ]]; then
    echo "$track" > "$MEDIA_FILE"
    echo "0" > "$SCROLL_FILE"
    echo "0" > "$PAUSE_FILE"
    scroll_pos=0
    pause_count=0
else
    scroll_pos=$(cat "$SCROLL_FILE" 2>/dev/null)
    pause_count=$(cat "$PAUSE_FILE" 2>/dev/null)
    [[ -z "$scroll_pos" ]] && scroll_pos=0
    [[ -z "$pause_count" ]] && pause_count=0
fi

# Dynamic visible length
visible_chars=$(( ${#track} * 1 / 2 ))
[[ $visible_chars -lt $VISIBLE_MIN ]] && visible_chars=$VISIBLE_MIN

# Handle play/pause behavior
if [[ "$player_status" == "Paused" ]]; then
    # Do not advance scroll position when paused
    :
else
    # Check if we're in pause period at the end
    if (( pause_count > 0 )); then
        pause_count=$((pause_count - 1))
        echo "$pause_count" > "$PAUSE_FILE"
    else
        # Scroll by 1 character (smoother than before)
        scroll_pos=$((scroll_pos + 1))

        # Loop handling - pause at end
        if (( scroll_pos >= ${#track} )); then
            scroll_pos=0
            pause_count=$PAUSE_CYCLES
            echo "$pause_count" > "$PAUSE_FILE"
        fi

        echo "$scroll_pos" > "$SCROLL_FILE"
    fi
fi

# Create scrolling text
if (( scroll_pos + visible_chars <= ${#track} )); then
    display_text="${track:scroll_pos:visible_chars}"
else
    wrap_len=$(( scroll_pos + visible_chars - ${#track} ))
    display_text="${track:scroll_pos}${track:0:wrap_len}"
fi

# Output JSON for Waybar
echo "{\"text\": \"$display_text\", \"class\": \"${player_status,,}\"}"
