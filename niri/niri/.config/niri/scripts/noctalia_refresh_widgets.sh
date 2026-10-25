#!/usr/bin/env bash
set -euo pipefail

# Restarts Noctalia when its saved widget layout no longer matches the generated one.
# v5 copies the generated widgets into its state file and that copy wins, so after the
# connected outputs change the new widgets are ignored until the saved copy is cleared,
# which only works while v5 is stopped.
# Usage: noctalia_refresh_widgets.sh [--check]
#   --check  only report whether a restart is needed (exit 0 stale, 1 current)

readonly CONFIG_DIR="${HOME}/.config/noctalia"
readonly STATE_FILE="${NOCTALIA_STATE_FILE:-${HOME}/.local/state/noctalia/settings.toml}"

# widget_order of a section, from the generated file and from the state file
function widget_order() {
    local file="${1}" section="${2}"
    [[ -f "${file}" ]] || return 0
    awk -v sec="[${section}]" '
        /^\[/ { in_sec = ($0 == sec) }
        in_sec && /^[[:space:]]*widget_order/ { gsub(/[[:space:]]/, ""); print; exit }
    ' "${file}"
}

function is_stale() {
    local section generated saved
    for section in desktop_widgets lockscreen_widgets; do
        generated="$(widget_order "${CONFIG_DIR}/$([[ "${section}" == desktop_widgets ]] && echo visualizer || echo lockscreen-widgets).toml" "${section}")"
        saved="$(widget_order "${STATE_FILE}" "${section}")"
        [[ -z "${saved}" || "${saved}" == "${generated}" ]] || return 0
    done
    return 1
}

function main() {
    if ! is_stale; then
        [[ "${1:-}" == "--check" ]] && exit 1
        return 0
    fi
    [[ "${1:-}" == "--check" ]] && exit 0

    # Killing v5 while it holds the session lock leaves niri on its red fail-safe screen
    while [[ "$(noctalia msg status 2>/dev/null | jq -r '.locked')" == "true" ]]; do
        sleep 2
    done

    pkill -x '.noctalia-wrapp' || true
    sleep 2
    python3 - "${STATE_FILE}" <<'EOF'
import re, sys
path = sys.argv[1]
parts = re.split(r'(?m)^(?=\[)', open(path).read())
keep = [p for p in parts if not p.lstrip().startswith(("[desktop_widgets", "[lockscreen_widgets"))]
open(path, "w").write("".join(keep))
EOF
    niri msg action spawn -- noctalia
}

main "$@"
