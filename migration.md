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
2. Baseline v5 config in TOML. In progress: `bar.toml`, `theme.toml`, `shell.toml`, and the custom palette are done. The theme still needs a review against v4. Idle, the lock screen, and wallpaper are done (`idle.toml`, `lockscreen.toml`, `wallpaper.toml`). Notifications and the OSD, audio, night light, and location are done (`notifications.toml`, `audio.toml`, `nightlight.toml`, `location.toml`). The session menu is done (`session.toml`). Clipboard history is already on by default in v5. The Control Center needed nothing, since you changed none of its v4 defaults. The lock screen's analog clock and compact layout are not ported (see Open items).
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
| `notifications toggleHistory` | `panel-toggle control-center notifications` | works, history is a Control Center tab |
| bar display toggle script | `bar-toggle` or `bar-auto-hide-set` | open, behavior not confirmed |

The dock toggle was removed. The dock is disabled in both versions and the old key never worked on nix.

## Decisions

- We install v5 from the distro package everywhere. On nix that is `pkgs.noctalia`. On Arch it is `pacman -S noctalia` from `[extra]`. On Ubuntu 26.04 it is the apt repository at `pkg.noctalia.dev`.
- The wrapper is scaffolding only. At cutover the callers switch to `noctalia msg` directly and the wrapper is deleted.
- The settings window is a regular toplevel in v5, so niri opens it floating (`dev.noctalia.Noctalia`, title "Noctalia Settings").
- We dropped the dock keybind and script.
- v5 config files live in `quickshell/noctalia/.config/noctalia/` as `*.toml`, split by topic. `~/.config/noctalia` resolves into that directory through Home Manager, so a new file is picked up on the next `noctalia msg config-reload`. We check every change with `noctalia config validate`.
- The v4 System Monitor widget showed CPU usage, CPU temperature, and memory together. v5 shows one stat per widget, so `bar.toml` defines three (`cpu`, `cpu-temp`, `memory`).
- Bar spacing was matched to v4 by measuring screenshots at 1.5x scale, not by eye. A spacer widget's gap is about 1.5 times its length plus 3 physical pixels. v4 spaced the right-hand widgets about 28 px apart and the stats about 16 px, so `bar.toml` uses spacers on both lanes. The bluetooth gaps still copy v4's extra-wide spacing.
- Workspace pills use `pill_scale = 0.68`, `active_pill_size = 2.3`, and `inactive_pill_size = 0.9`, which matched v4's 38x17 and 16x17 px pills. The battery uses `display_mode = "graphic"` at `scale = 0.9` with `font_scale = 1.11` so its text keeps its size.
- Right-click on the empty bar opened the Control Center, so `bar.toml` binds the dead-zone `right` action to `none`. `shell.toml` sets `open_near_click_control_center = true` so the Control Center drops down under the widget you click. Keybinds still open it at the bar center.
- The media widget sits in the center lane next to the clock, with a spacer between them. It is locked to 180 px (`min_length` and `max_length` both 180), so the layout never shifts when a track starts or changes, and longer titles clip and scroll on hover. A leading spacer (`sp-lead`) centers the logo on the screen, which is where the visualizer's middle sits. Scroll mode `always` was tried and rejected: it wraps the title with no gap, and v5 has no scroll interval option. It stays on the bar even with no player, where it shows its built-in Nothing Playing placeholder (`hide_when_no_media = false`).
- The audio visualizer is a desktop widget, not a bar widget, so it can hang from the bar's bottom edge like the reference rice. `niri/niri/.config/niri/scripts/visualizer_layout.sh` generates its config (`visualizer.toml`, untracked) for every connected output from niri's logical width, because v5 only takes fixed `cx` coordinates per output. `output_watch.sh` runs it at startup and whenever the set of outputs changes, so it follows monitor and laptop-panel changes. It has no background card and keeps the primary and secondary colors. One widget is capped at 128 bands, so it uses two mirrored halves (256 bars, bass in the middle) that overlap by about 72 px. The lowest bands at each inner edge are near zero and can leave a gap in the middle, so the halves overlap to close it. The look still varies a little with the music, because how quiet those bands are changes from moment to moment. Desktop widgets render on the Bottom layer, so windows cover it.
- A separator between the clock and the player shows the OS logo, tinted with the theme's `tertiary` color at `scale = 1.3`. The logo SVGs are tracked in `logos/` (`nixos.svg`, `arch.svg`, `ubuntu.svg`, all single-color so the tint works). `bar.toml` defines the widget with a diamond fallback, and an untracked `local.toml` on each machine sets `custom_image` to that machine's logo with `custom_image_colorize = true`. Bootstrap and the nix config should write `local.toml` from the detected distro when we migrate the other machines. The Arch and Ubuntu logos come from the Simple Icons set, so check trademark terms if the repository is ever shared widely.
- Idle uses the v4 timings: lock at 300 s, screen off at 600 s, suspend at 1800 s (locks first), with a 5 s dim before each action. v5 ships with every idle behavior disabled, so without `idle.toml` nothing locks or sleeps. A fast test (8 s and 16 s) confirmed the screen-off fires. The lock firing on idle was not directly confirmed.
- The lock screen has no transition (`transition = []`). Every effect (we tried zoom) added a visible delay to locking and unlocking, probably from capturing the large output, and an instant lock also avoids a bright flash between the idle dim and the lock screen. v5.2.1 only has fade, wipe, disc, stripes, zoom, and honeycomb. The docs also list vortex, pixel, diamond, golden, and melt, which this version rejects as unknown values.
- Wallpaper uses the v4 values in `wallpaper.toml`: crop fill, black fallback, honeycomb at 1000 ms, one shared folder (`~/.dotfiles.di/wallpapers`, and `~` works in v5), no rotation, and the backdrop disabled. Wallpapers are still picked per output by `wallpaper_cycle.sh` through `wallpaper-set`, which v5 persists in its own state file. v4's `wallpaperChange` hook (`scripts/normalize_wallpaper_paths.sh`) only rewrote paths in v4's `settings.json`, so it is obsolete and can be deleted at cutover.
- Keybinds use Noctalia's native commands wherever one exists. Volume, mic, media, brightness, the screenshot keys, the wallpaper picker, and the bar toggle call `noctalia msg` directly, which also shows v5's OSD. They no longer work on v4. Custom pieces stay where v5 has no equivalent: `record-region` (wf-recorder), the resolution-matched wallpaper cycle (`wallpaper_cycle.sh`), and the click-to-pick window screenshot (`screenshot_window.sh`, built on niri's `pick-window`).
- Screenshots: `Print` captures a region to the clipboard and `~/Documents/Screenshots` with no editor (`screenshot.toml`), `Shift+Print` runs `screenshot-annotate`, and `Ctrl+Shift+Print` lets you click a window to capture it. niri's `screenshot-path` points at the same folder. v5 has no Space-key switch from region to window, and its `screenshot-window` command is newer than 5.2.1. niri's picker gives no hover highlight that we know of.
- All of the shell's own sounds are off (`audio.toml`, `enable_sounds = false`): the screenshot shutter, volume change, notifications, and charger plug sounds.
- Notifications and the OSD are in `notifications.toml`. The toast position (top center), opacity (0.8), border color (secondary), follow-focused-output, and one hour of history were chosen in the Settings window, which writes `~/.local/state/noctalia/settings.toml`, so we copied them into the tracked file. From v4 we kept the overlay layer for toasts and the OSD's 2 s delay and opacity. The OSD sits at the top center like the toasts. v5 has no keys for v4's compact density, per-urgency durations (3, 5, 15 s), markdown, or the media, battery, and keyboard-layout toast toggles, and `respectExpireTimeout` is not mapped. v5 shows OSD popups for more things than v4 did (wifi, bluetooth, caffeine, and others), left at their defaults.
- Night light, location, and weather use the v4 values (`nightlight.toml`, `location.toml`: 6500 K day, 4993 K night, South Riding VA, Fahrenheit). Color adjustment does not work on DP-3 right now. niri advertises gamma control, but gammastep and wlsunset (v4's tool) both report it failing on that output, and forcing night light in v5 does nothing. It worked in v4 before the Hybrid GPU mode and the iGPU render-device change, which we suspect but have not confirmed. Revisit after the full cutover and a reboot.
- The port covers only what we changed from v4's shipped defaults, found by diffing `settings.json` against `Assets/settings-default.json`. Everything else stays at v5 defaults.
- The session menu uses v5's five default actions with the v4 10 s countdown on logout, suspend, reboot, and shutdown (`session.toml`). Lock has none, since a countdown would only add a click.
- The theme is a custom palette (`palettes/CatppuccinLavender.json`) built from v4's generated `colors.json`, selected in `theme.toml`. v5's built-in Catppuccin has no accent variants.
- In `bar.toml` we only carry over v4 values that map clearly: position, background opacity, widget spacing, clock format, workspace pill style, and media options. Thickness, padding, radius, and blur stay at v5 defaults until we see the bar and decide.
- We did not carry over the clamshell script from the earlier abandoned branch. Niri already disables the laptop panel when the lid closes, and the script hardcoded another machine's output names.

## Things we learned

- On nix the v4 process is `.quickshell-wrapped`, so `pgrep -x qs` never matches. Scripts that detect the running shell use the full command line instead.
- `layout_profile.sh` used to overwrite the whole of `local.kdl` whenever the monitor setup changed. It now replaces only its own layout block, so per-machine overrides such as the ROG render device survive.
- v5 has no standalone notification history panel. History is the `notifications` tab of the Control Center. Other tab ids are `home`, `media`, `audio`, `monitor`, `system`, `network`, `bluetooth`, `weather`, `calendar`, `screen-time`, and `power`.
- `local.kdl` is the gitignored per-machine override that the shared niri config includes at the end.

## Open items

- Upgrade to Noctalia 5.3.0 by running `nru` (a full flake update) once the remaining settings are ported, with no separate pin. 5.3.0 moves the battery text inside the pill in graphic mode. We are on 5.2.1 until then, so the battery label sits beside the pill. The documented `hide_when_idle` option for the media widget is also newer than 5.2.1, which reports it as an unknown setting. Until then the media widget stays visible while a browser player is paused, because Firefox keeps its player registered.
- Screen recording: only region recording exists (`record-region`, whose toasts were 2 s and 8 s and are now both 4 s, changed in the nix repo). A record-screen bind is easy with `wf-recorder -o`, and true window recording would need a portal-based recorder.
- The v4 lock screen's analog clock and compact layout are not ported. v5 has `layout = "compact"` on the lock screen login box, but it only applies when `lockscreen_widgets` is enabled, and those widgets are placed with fixed per-output coordinates, so a dynamic setup needs a generator like the visualizer's. The docs describe only a digital `format` for the lock screen clock, so an analog clock may not exist in 5.2.1. Revisit after the 5.3.0 upgrade.
- Caffeine (v5's idle inhibitor) blocks every idle behavior while on. It persists, so check it when idle does not fire. The v4 helper services `noctalia-media-inhibit` and `noctalia-plex-dnd` still run but call v4 IPC and do nothing in v5.
- Bar items with no clean v5 mapping yet: right-click on the bar opening the Control Center, the volume widget's middle-click command (`pwvucontrol`), the battery widget's graphic display mode, and the v4 media widget's progress ring and ring visualizer (v5 has a separate `audio_visualizer` widget).
- Tune the v5 lock screen, which now has effects.
- Choose where the Control Center opens instead of the screen center.
- The nix `lock-before-suspend` service still calls v4 IPC directly and the module decides whether to apply itself by looking for `noctalia-qs`.
- Port the v4 settings and decide which of the custom v4 features survive: notification display rules, the music-only media toast, session menu blur, the ring visualizer, the lock screen layout, the WiFi refresh after resume, and the two helper scripts for media inhibit and Plex do-not-disturb.
- Replace the v4 plugins with Luau equivalents or drop them.
- The hyprland, sway, and river script directories still call v4 IPC. Decide whether those compositors stay supported.
- Update the bootstrap installer and package lists for Arch and Ubuntu.
- Near the end, evaluate `noctalia-greeter` (https://github.com/noctalia-dev/noctalia-greeter), a greetd greeter that syncs wallpaper and palette from the v5 shell (`noctalia msg greeter-sync`). Today NixOS uses SilentSDDM with the catppuccin-mocha theme, and the Arch and Ubuntu bootstrap configures no greeter. Check multi-monitor and fingerprint behavior and how to hand off safely from the current display manager before switching.

## Migrating the other machines

To fill in once the cutover on this laptop is done. For each machine we need the install route for its distro, the TOML config stowed from this repository, the niri startup line and keybinds on `noctalia msg`, and a rollback note.
