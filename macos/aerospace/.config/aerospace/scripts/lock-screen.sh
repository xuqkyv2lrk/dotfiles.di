#!/usr/bin/env bash
# Locks the screen — bound to alt-l, mirroring niri's Mod+L lock binding.
#
# Strategies, in order:
#   1. SACLockScreenImmediate — a private symbol in login.framework that IS
#      the native "lock now" call (same one Apple menu → Lock Screen and
#      ⌃⌘Q ultimately reach). A one-line C shim calls it directly — no
#      synthetic input events posted. Compiled once on first run and cached,
#      since it needs no config/permissions and never behaves differently
#      after a lock/unlock cycle.
#   2. CGSession -suspend — the pre-Sequoia equivalent of #1. Kept as a
#      fallback for older macOS; removed entirely as of macOS 26.
#   3. Simulate the system's own Lock Screen shortcut (^⌘Q) via System
#      Events' "keystroke". Works everywhere and needs no compiler, but it
#      posts a *synthetic* keystroke rather than calling the lock API
#      directly — after a lock/unlock cycle the session can be left in a
#      state where synthetic key injection (not physical hotkeys, which is
#      why other AeroSpace bindings stay unaffected) is silently swallowed.
#      Kept only as a fallback for machines without clang.
#   4. pmset displaysleepnow — sleeps the display. Combined with the
#      standard "Require password after sleep" setting in System Settings
#      → Lock Screen, this still ends up locked; last-resort only.
set -euo pipefail

cache_dir="${XDG_CACHE_HOME:-${HOME}/.cache}/aerospace"
lock_bin="${cache_dir}/lock-screen"

if [[ ! -x "${lock_bin}" ]] && command -v clang &>/dev/null; then
    mkdir -p "${cache_dir}"
    tmp_src="$(mktemp -t lock-screen-XXXXXX.c)"
    cat > "${tmp_src}" <<'EOF'
extern int SACLockScreenImmediate(void);
int main(void) { return SACLockScreenImmediate(); }
EOF
    clang -F /System/Library/PrivateFrameworks -framework login \
        -o "${lock_bin}" "${tmp_src}" 2>/dev/null || true
    rm -f "${tmp_src}"
fi

if [[ -x "${lock_bin}" ]] && "${lock_bin}"; then
    exit 0
fi

cgsession="/System/Library/CoreServices/Menu Extras/User.menu/Contents/Resources/CGSession"
if [[ -x "${cgsession}" ]]; then
    "${cgsession}" -suspend && exit 0
fi

if osascript -e 'tell application "System Events" to keystroke "q" using {control down, command down}' 2>/dev/null; then
    exit 0
fi

pmset displaysleepnow
