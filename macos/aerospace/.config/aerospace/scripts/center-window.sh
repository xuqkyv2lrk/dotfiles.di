#!/usr/bin/env bash
# Centers the first window of the given app on the main screen. Used by
# on-window-detected callbacks for apps that should always spawn centered
# instead of wherever macOS/the app last remembered (e.g. Okta Verify's MFA
# prompt, which otherwise reopens at its last floating position).
#
# Called two ways:
#   - With an explicit app name (hardcoded per-app on-window-detected rules).
#   - With no argument, from the generic floating-dialog rule in
#     aerospace.toml — falls back to AEROSPACE_WINDOW_ID (set by AeroSpace on
#     every on-window-detected callback) to look up the just-detected
#     window's owning app via `aerospace list-windows`.
set -euo pipefail

app_name="${1:-}"
if [[ -z "$app_name" ]]; then
    : "${AEROSPACE_WINDOW_ID:?center-window.sh: no app name given and AEROSPACE_WINDOW_ID unset}"
    app_name="$(aerospace list-windows --window-id "$AEROSPACE_WINDOW_ID" --format '%{app-name}')"
fi

# The window may still be rendering right as on-window-detected fires;
# give it a beat so `size of window` isn't read before layout settles.
sleep 0.2

# NSScreen (AppKit) instead of `tell application "Finder" to get bounds of
# window of desktop` — the Finder-based trick triggers a separate macOS
# Automation permission prompt (distinct from the Accessibility grant System
# Events already has) and silently hangs headless callers until a human
# approves it.
osascript <<EOF
use framework "AppKit"
use scripting additions

set screenFrame to (current application's NSScreen's mainScreen()'s frame())
set screenW to item 1 of item 2 of screenFrame
set screenH to item 2 of item 2 of screenFrame

tell application "System Events"
    tell process "${app_name}"
        set targetWindow to first window
        set {winW, winH} to size of targetWindow
        set position of targetWindow to {((screenW - winW) / 2), ((screenH - winH) / 2)}
    end tell
end tell
EOF
