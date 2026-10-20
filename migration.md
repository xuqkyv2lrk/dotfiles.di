# Noctalia v4 to v5 migration

This document tracks our move from Noctalia v4 to v5. We update it as we go, so it always shows what is done, what is left, and what we learned. It lives on the `feat/noctalia-v5` branch and is the checklist we follow when we migrate the other machines.

## Why this is a project

v5 is a ground-up rewrite, not an upgrade.

- It is a native C++ program on OpenGL ES, started with `noctalia`. v4 is Quickshell and QML, started with `qs -p <dir>`.
- Configuration is TOML. Hand-written files in `~/.config/noctalia/` are merged alphabetically. The Settings UI writes `~/.local/state/noctalia/settings.toml`, which wins on conflict. v4 used `settings.json`.
- Nothing is migrated automatically, so we recreate our v4 settings by hand.
- Plugins are Luau with a `plugin.toml` manifest, so our v4 QML plugins do not load.
- The IPC is new: `noctalia msg <command>` replaces `qs ipc call <target> <function>`.
- The two versions install side by side without colliding, but only one can run at a time because both want the bar, the notification daemon, and the lock screen.

Upstream documentation: https://docs.noctalia.dev

## Where we are

We run both versions on the ROG laptop while we port. A temporary wrapper script decides which one niri talks to, so we can switch back and forth without editing the compositor config.

- Install: v5 is installed beside v4 through nix (`pkgs.noctalia`, 5.2.1 in our pinned nixpkgs). v4 still runs from the fork submodule at `quickshell/noctalia-shell`.
- Switch: `niri/niri/.config/niri/scripts/noctalia_ctl.sh` takes the v4 `qs ipc call` signature and dispatches to either shell. The choice comes from `~/.config/niri/noctalia-version` (`v4` or `v5`, untracked, defaults to v4).
- Rollback: delete `noctalia-version` and start v4 again. Nothing about v4 was changed.

## Stages

1. Switch layer and hotkeys. Done on niri.
2. Baseline v5 config in TOML. In progress: `bar.toml` is done (bar, lanes, clock, workspaces, system monitor, media). Lock screen, notifications, wallpaper, idle, and theme are still to do.
3. Port the v4 settings into TOML.
4. Triage the custom v4 work (keep, replace, or drop each item).
5. Packaging and bootstrap for Arch and Ubuntu.
6. Cutover on this laptop: remove the wrapper, v4, the fork submodule, and the v4-only helpers.
7. Migrate the other machines.

## IPC mapping

Each row was checked against `noctalia msg --help` on the installed v5, and the keys were tested live.

| v4 call | v5 command | Status |
|---|---|---|
| `launcher toggle` | `panel-toggle launcher` | works |
| `launcher clipboard` | `panel-toggle clipboard` | works |
| `sessionMenu toggle` | `panel-toggle session` | works |
| `controlCenter toggle` | `panel-toggle control-center` | works, opens centered |
| `settings toggle` | `settings-toggle` | works, opens as a window |
| `lockScreen lock` | `session lock` | works |
| `idleInhibitor toggle` | `caffeine-toggle` | works |
| `media toggle` | `media toggle` | works |
| `wallpaper set <path> [screen]` | `wallpaper-set [connector] <path>` | works, argument order is swapped |
| `notifications toggleHistory` | unknown | open, no panel id is documented |
| bar display toggle script | `bar-toggle` or `bar-auto-hide-set` | open, behavior not confirmed |

The dock toggle was removed. The dock is disabled in both versions and the old key never worked on nix.

## Decisions

- We install v5 from the distro package everywhere. On nix that is `pkgs.noctalia`. On Arch it is `pacman -S noctalia` from `[extra]`. On Ubuntu 26.04 it is the apt repository at `pkg.noctalia.dev`.
- The wrapper is scaffolding only. At cutover the callers switch to `noctalia msg` directly and the wrapper is deleted.
- The settings window is a regular toplevel in v5, so niri opens it floating (`dev.noctalia.Noctalia`, title "Noctalia Settings").
- We dropped the dock keybind and script.
- v5 config files live in `quickshell/noctalia/.config/noctalia/` as `*.toml`, split by topic. `~/.config/noctalia` resolves into that directory through Home Manager, so a new file is picked up on the next `noctalia msg config-reload`. We check every change with `noctalia config validate`.
- The v4 System Monitor widget showed CPU usage, CPU temperature, and memory together. v5 shows one stat per widget, so `bar.toml` defines three (`cpu`, `cpu-temp`, `memory`).
- In `bar.toml` we only carry over v4 values that map clearly: position, background opacity, widget spacing, clock format, workspace pill style, and media options. Thickness, padding, radius, and blur stay at v5 defaults until we see the bar and decide.
- We did not carry over the clamshell script from the earlier abandoned branch. Niri already disables the laptop panel when the lid closes, and the script hardcoded another machine's output names.

## Things we learned

- On nix the v4 process is `.quickshell-wrapped`, so `pgrep -x qs` never matches. Scripts that detect the running shell use the full command line instead.
- `layout_profile.sh` used to overwrite the whole of `local.kdl` whenever the monitor setup changed. It now replaces only its own layout block, so per-machine overrides such as the ROG render device survive.
- `local.kdl` is the gitignored per-machine override that the shared niri config includes at the end.

## Open items

- Find the v5 way to show notification history, possibly a Control Center tab.
- Decide what replaces the v4 bar display toggle.
- Bar items with no clean v5 mapping yet: right-click on the bar opening the Control Center, the volume widget's middle-click command (`pwvucontrol`), the battery widget's graphic display mode, and the v4 media widget's progress ring and ring visualizer (v5 has a separate `audio_visualizer` widget).
- Tune the v5 lock screen, which now has effects.
- Choose where the Control Center opens instead of the screen center.
- The nix `lock-before-suspend` service still calls v4 IPC directly and the module decides whether to apply itself by looking for `noctalia-qs`.
- Port the v4 settings and decide which of the custom v4 features survive: notification display rules, the music-only media toast, session menu blur, the ring visualizer, the lock screen layout, the WiFi refresh after resume, and the two helper scripts for media inhibit and Plex do-not-disturb.
- Replace the v4 plugins with Luau equivalents or drop them.
- The hyprland, sway, and river script directories still call v4 IPC. Decide whether those compositors stay supported.
- Update the bootstrap installer and package lists for Arch and Ubuntu.

## Migrating the other machines

To fill in once the cutover on this laptop is done. For each machine we need the install route for its distro, the TOML config stowed from this repository, the niri startup line and keybinds on `noctalia msg`, and a rollback note.
