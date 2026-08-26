#!/usr/bin/env bash
set -euo pipefail

# Set all columns in the focused workspace to a given width.
# Usage: set_workspace_width.sh <width>
# Example: set_workspace_width.sh 50%

WIDTH="${1:?Width required (e.g. 50%)}"

# Save focused window to restore focus after iterating columns
FOCUSED_ID=$(niri msg --json focused-window 2>/dev/null | jq -r '.id // empty')

# Get focused workspace ID
WORKSPACE_ID=$(niri msg --json workspaces | jq -r '.[] | select(.is_focused) | .id')

# Upper bound: number of windows on the workspace (columns <= windows)
WIN_COUNT=$(niri msg --json windows | jq -r --argjson ws "$WORKSPACE_ID" '[.[] | select(.workspace_id == $ws)] | length')

if [[ "$WIN_COUNT" -eq 0 ]]; then
    exit 0
fi

niri msg action focus-column-first

for _ in $(seq 1 "$WIN_COUNT"); do
    niri msg action set-column-width "$WIDTH"
    # Stop at rightmost column without wrapping
    niri msg action focus-column-right 2>/dev/null || break
done
# Handle the rightmost column which focus-column-right skips
niri msg action set-column-width "$WIDTH"

# Restore original focus
if [[ -n "$FOCUSED_ID" ]]; then
    niri msg action focus-window --id "$FOCUSED_ID"
fi
