# Noctalia v4 to v5 Migration

This document tracks our move from Noctalia v4 to v5 across every compositor
setup in this repository. We update it as we go, so it always reflects what is
done, what is left, and what we have learned along the way.

## Why This Is a Project, Not a Bump

Noctalia v5 went GA with v5.0.1 on 2026-09-03 (v5.2.0 is current as of
2026-09-27). It is a ground-up rewrite rather than an incremental release:

- It is a native Wayland program built on OpenGL ES, with no Qt, QML, or
  Quickshell dependency. We no longer run it with `qs -p <config dir>`.
- Configuration moves from `settings.json` to TOML with hot reload and
  GUI-managed overrides.
- Plugins are written in Luau with a `plugin.toml` manifest instead of QML with
  a `manifest.json`, so none of our v4 plugins load as-is.
- The IPC surface is new, so every `qs ipc ... call <target> <action>` binding
  needs to be mapped to its v5 equivalent.
- The plugin repositories changed: `noctalia-dev/noctalia-plugins` (v4) is
  replaced by `noctalia-dev/official-plugins` and
  `noctalia-dev/community-plugins`.

The release notes only describe automatic migrations between v5 betas. We have
not found an importer for a v4 `settings.json`, so we should plan to recreate
our settings by hand.

Useful references:

- Upstream repository: https://github.com/noctalia-dev/noctalia
- Documentation: https://docs.noctalia.dev
- Official plugins: https://github.com/noctalia-dev/official-plugins
- Community plugins: https://github.com/noctalia-dev/community-plugins

## Where We Are Today

We pin v4 through the `quickshell/noctalia-shell` submodule, currently at
`v4.6.7-229-gb3fd10b` (2026-04-19). The submodule points at our GitLab mirror,
which stopped receiving tags at `v4.6.7` and has no v5 history.

Our v4 settings live in `quickshell/noctalia/.config/noctalia/`:

- `settings.json` (v4 schema version 59)
- `plugins.json` (plugin sources and enabled state)
- `plugins/fancy-audiovisualizer/` (vendored plugin, see below)

GNOME does not use Noctalia, so the `gnome/` packages are out of scope.

## Decisions

We record each decision here once we make it, with a short reason.

- [ ] How we install v5: distro package, AUR, or building from source. The
  submodule most likely goes away, since v5 is no longer a QML directory that
  Quickshell loads.
- [ ] Whether we keep a GitLab mirror of upstream at all, and if so, whether
  it tracks v5.
- [ ] Where the v5 TOML config lives in this repository, and how it is stowed.

## Work Items

### Installation and startup

Each compositor starts v4 with `qs -p`. These lines change to whatever v5's
launch command is.

- [ ] `niri/niri/.config/niri/config.kdl:52`
- [ ] `hyprland/hypr/.config/hypr/config.d/autostart.conf:7`
- [ ] `sway/sway/.config/sway/config:295`. This line points at
  `quickshell/noctalia` (our settings package) instead of
  `quickshell/noctalia-shell`, which looks like an existing bug. We should
  confirm and fix it as part of this work.
- [ ] Update the package list in
  [dotfiles.bootstrap](https://gitlab.com/wd2nf8gqct/dotfiles.bootstrap) to
  install v5 and drop Quickshell if nothing else needs it.
- [ ] Remove the `quickshell/noctalia-shell` submodule once v5 is installed as
  a package (pending the installation decision above).

### IPC bindings

Every binding below uses the v4 form
`qs ipc -p "${HOME}/.dotfiles.di/quickshell/noctalia-shell" call <target> <action>`.
We fill in the v5 column from the v5 IPC reference, then update each call
site.

| v4 call | v5 equivalent | Call sites |
|---|---|---|
| `launcher toggle` | TBD | `niri/niri/.config/niri/scripts/launcher.sh:4`, `hyprland/hypr/.config/hypr/scripts/launcher.sh:4`, `sway/sway/.config/sway/scripts/launcher.sh:4` |
| `launcher clipboard` | TBD | `niri/niri/.config/niri/scripts/clipboard.sh:5`, `hyprland/hypr/.config/hypr/config.d/binds.conf:87` |
| `notifications toggleHistory` | TBD | `niri/niri/.config/niri/scripts/notifications.sh:4`, `hyprland/hypr/.config/hypr/scripts/notifications.sh:4`, `sway/sway/.config/sway/scripts/notifications.sh:4` |
| `sessionMenu toggle` | TBD | `niri/niri/.config/niri/scripts/session_menu.sh:4`, `hyprland/hypr/.config/hypr/scripts/session_menu.sh:4`, `sway/sway/.config/sway/scripts/session_menu.sh:4` |
| `lockScreen lock` | TBD | `niri/niri/.config/niri/config.kdl:171`, `hyprland/hypr/.config/hypr/config.d/binds.conf:26`, `sway/sway/.config/sway/config:290` |
| `settings toggle` | TBD | `niri/niri/.config/niri/config.kdl:179`, `hyprland/hypr/.config/hypr/config.d/binds.conf:85` |
| `controlCenter toggle` | TBD | `niri/niri/.config/niri/config.kdl:180`, `hyprland/hypr/.config/hypr/config.d/binds.conf:86` |
| `dock toggle` | TBD | `niri/niri/.config/niri/scripts/dock_toggle.sh:5` |
| `media toggle` | TBD | `niri/niri/.config/niri/scripts/media.sh:4` |

### Settings

- [ ] Recreate `settings.json` as v5 TOML. We work through it section by
  section (bar and widgets, dock, launcher, notifications, lock screen, idle,
  wallpaper, theme) and note anything v5 cannot express.
- [ ] Idle handling. The README notes that Noctalia owns idle behavior for our
  compositors, so we need to confirm v5's idle and lock settings cover what v4
  did before we switch any machine over.
- [ ] Per-monitor settings. Our v4 desktop widgets are keyed to `HDMI-A-1`;
  v5 monitor selectors can also match make, model, or serial, which may be
  more robust across machines.
- [ ] Media panel tuning from `3eee34e`.

### Plugins

#### Fancy Audiovisualizer (music playback visualizer)

This is the circular, shader-based visualizer we set up in `3eee34e` and
refreshed in `1264ea9`. It is the one plugin we most want to keep. Upstream
has not ported it: it is absent from both v5 plugin repositories.

Our current v4 setup, for reference when we rebuild it:

- Desktop widget on `HDMI-A-1` at `x=4700, y=150`, with a background, at
  `widgetScale` 1.8.
- `visualizationMode` 3, `sensitivity` 1.5, `rotationSpeed` 0.5, `barWidth`
  0.6, `ringOpacity` 0.8, `bloomIntensity` 0.5, `waveThickness` 1.0,
  `innerDiameter` 0.7, `fadeWhenIdle` false, theme colors (no custom colors).
- Rendering lives in
  `quickshell/noctalia/.config/noctalia/plugins/fancy-audiovisualizer/shaders/visualizer.frag`.

Options, in the order we should check them:

- [ ] Check whether v5 ships a built-in circular visualizer. The v5.2.0 notes
  mention a fix to "circular visualizer rendering", and v5 has a built-in
  audio visualizer bar widget, so this may already cover most of what we want.
- [ ] Check whether the v5 plugin API lets a desktop widget run a custom
  fragment shader. If it does, we can port the plugin to Luau and reuse the
  existing shader logic.
- [ ] If neither works, look at the community plugins for a close substitute,
  or consider contributing a port upstream.

#### Plugin registry

- [ ] Replace `plugins.json` (which points at the retired
  `noctalia-plugins` repository) with v5's plugin configuration.

### Documentation

- [ ] Update the Noctalia section and stow instructions in `README.md`.
- [ ] Update this document's decisions and tables as items land, and delete it
  once the migration is complete.

## Rollout

We migrate one compositor at a time so a working desktop is always available.
A reasonable order is niri first (it has the most bindings), then Hyprland,
then Sway. Each one is done when its startup line and every binding in the
table above work under v5.

## Notes

We add findings here as we go: gotchas, v5 behavior that differs from v4, and
anything worth remembering for the next machine.
