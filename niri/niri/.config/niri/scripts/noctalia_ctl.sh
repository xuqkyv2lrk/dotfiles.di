#!/usr/bin/env bash
set -euo pipefail

# TEMPORARY: dispatches Noctalia IPC to v4 (qs) or v5 (noctalia msg) while v5 is
# being ported. Deleted at v5 cutover; callers then use `noctalia msg` directly.
#
# Usage:
#   noctalia_ctl.sh start
#   noctalia_ctl.sh call <target> <function> [args...]   (v4 `qs ipc call` signature)
#
# Version comes from NOCTALIA_VERSION, else ~/.config/niri/noctalia-version, else v4.
# NOCTALIA_CTL_DRYRUN=1 prints the command instead of running it.

readonly V4_PATH="${HOME}/.dotfiles.di/quickshell/noctalia-shell"
readonly VERSION_FILE="${HOME}/.config/niri/noctalia-version"

function usage() {
    sed -n '/^# Usage:/,/^$/p' "${0}" | sed 's/^# \{0,1\}//'
}

function get_version() {
    if [[ -n "${NOCTALIA_VERSION:-}" ]]; then
        printf "%s" "${NOCTALIA_VERSION}"
    elif [[ -f "${VERSION_FILE}" ]]; then
        tr -d '[:space:]' < "${VERSION_FILE}"
    else
        printf "v4"
    fi
}

function run() {
    if [[ "${NOCTALIA_CTL_DRYRUN:-}" == "1" ]]; then
        printf '%q ' "$@"
        printf '\n'
    else
        "$@"
    fi
}

function die() {
    printf "noctalia_ctl: %s\n" "$*" >&2
    exit 2
}

function start_shell() {
    case "$(get_version)" in
        v4) run qs -p "${V4_PATH}" ;;
        v5) run noctalia ;;
        *) die "unknown version '$(get_version)'" ;;
    esac
}

function call_v4() {
    local target="${1}"
    shift

    # lockScreen must work with no focused display
    if [[ "${target}" == "lockScreen" ]]; then
        run qs ipc --any-display -p "${V4_PATH}" call "${target}" "$@"
    else
        run qs ipc -p "${V4_PATH}" call "${target}" "$@"
    fi
}

# v4 target/function -> v5 msg command
function call_v5() {
    local target="${1}"
    local fn="${2:-}"
    shift 2 || true

    case "${target} ${fn}" in
        "launcher toggle")           run noctalia msg panel-toggle launcher ;;
        "launcher clipboard")        run noctalia msg panel-toggle clipboard ;;
        "sessionMenu toggle")        run noctalia msg panel-toggle session ;;
        "controlCenter toggle")      run noctalia msg panel-toggle control-center ;;
        "settings toggle")           run noctalia msg settings-toggle ;;
        "lockScreen lock")           run noctalia msg session lock ;;
        "idleInhibitor toggle")      run noctalia msg caffeine-toggle ;;
        "dock toggle")               run noctalia msg dock-toggle ;;
        "media toggle")              run noctalia msg media toggle ;;
        "wallpaper set")
            # v4 takes <path> [screen]; v5 takes [connector] <path>
            if [[ $# -ge 2 ]]; then
                run noctalia msg wallpaper-set "${2}" "${1}"
            else
                run noctalia msg wallpaper-set "${1}"
            fi
            ;;
        "notifications toggleHistory") die "no v5 mapping yet for notifications history" ;;
        *) die "no v5 mapping for '${target} ${fn}'" ;;
    esac
}

function main() {
    local cmd="${1:-}"

    case "${cmd}" in
        start) start_shell ;;
        call)
            shift
            [[ $# -ge 2 ]] || die "call needs <target> <function>"
            case "$(get_version)" in
                v4) call_v4 "$@" ;;
                v5) call_v5 "$@" ;;
                *) die "unknown version '$(get_version)'" ;;
            esac
            ;;
        -h|--help|"") usage ;;
        *) die "unknown command '${cmd}'" ;;
    esac
}

main "$@"
