<div align="center">
<img src="./_docs/ui-circular.png" alt="dotfiles.di" width="250px" />
<h3>dotfiles.di</h3>
<p>Desktop interface configurations for Hyprland, Niri, Sway, and GNOME — managed with GNU Stow.</p>
<p>
  <a href="https://opensource.org/licenses/BSD-3-Clause"><img src="https://img.shields.io/badge/License-BSD%203--Clause-blue.svg" alt="License" /></a>
  <a href="https://gitlab.com/wd2nf8gqct/dotfiles.di"><img src="https://img.shields.io/badge/GitLab-Main-orange.svg?logo=gitlab" alt="GitLab" /></a>
  <a href="https://github.com/xuqkyv2lrk/dotfiles.di"><img src="https://img.shields.io/badge/GitHub-Mirror-black.svg?logo=github" alt="GitHub Mirror" /></a>
  <a href="https://codeberg.org/iw8knmaDD5/dotfiles.di"><img src="https://img.shields.io/badge/Codeberg-Mirror-2185D0.svg?logo=codeberg" alt="Codeberg Mirror" /></a>
</p>
<p>
  <a href="https://archlinux.org"><img src="https://img.shields.io/badge/Arch%20Linux-1793D1?logo=arch-linux&logoColor=fff&style=flat" alt="Arch Linux" /></a>
  <a href="https://ubuntu.com"><img src="https://img.shields.io/badge/Ubuntu-E95420?style=flat&logo=ubuntu&logoColor=white" alt="Ubuntu" /></a>
</p>
</div>


<br />

<div align="center">
<h3 style="margin-bottom: 0;">
<img src="./_docs/gnome/logo.svg" width="36px" style="vertical-align: top; margin-right: 3px" /><br />
GNOME</h3>
<div style="margin-top: 0; font-size: 0.9em;">
A modern, user-friendly desktop environment focused on simplicity&nbsp;&nbsp;&nbsp;[ <a href="https://github.com/GNOME/gnome-shell">GitHub</a> · <a href="https://help.gnome.org/">Guide</a> ]
</div>
<br />
<img src="./_docs/gnome/screenshot_one.png" alt="GNOME Screenshot One" width="260px" />
<img src="./_docs/gnome/screenshot_two.png" alt="GNOME Screenshot Two" width="260px" />
<img src="./_docs/gnome/screenshot_three-one.png" alt="GNOME Screenshot Two" width="260px" />
</div>

<br />

<div align="center">
<h3 style="margin-bottom: 0;">
<img src="./_docs/hyprland/logo.svg" width="28px" style="vertical-align: text-top; margin-right: 5px" /><br />
Hyprland
</h3>
<div style="margin-top: 0; font-size: 0.9em;">
A blazing fast tiling Wayland compositor with cat-like reflexes&nbsp;&nbsp;&nbsp;[ <a href="https://github.com/hyprwm/Hyprland">GitHub</a> · <a href="https://wiki.hyprland.org/">Wiki</a> ] 
</div>
<br />
</div>

<br />

<div align="center">
<h3 style="margin-bottom: 0;">
<img src="./_docs/sway/logo.svg" width="36px" style="vertical-align: top; margin-right: 5px" /><br />
Sway</h3>
<div style="margin-top: 0; font-size: 0.9em;">
A tiling Wayland compositor and drop-in replacement for i3&nbsp;&nbsp;&nbsp;[ <a href="https://github.com/swaywm/sway">GitHub</a> · <a href="https://github.com/swaywm/sway/wiki">Wiki</a> ]
</div>
<br />
</div>

<br />

<div align="center">
<h3 style="margin-bottom: 0;">
<img src="./_docs/niri/logo.svg" width="36px" style="vertical-align: top; margin-right: 5px" /><br />
Niri</h3>
<div style="margin-top: 0; font-size: 0.9em;">
A scrollable-tiling Wayland compositor&nbsp;&nbsp;&nbsp;[ <a href="https://github.com/YaLTeR/niri">GitHub</a> · <a href="https://github.com/YaLTeR/niri/wiki">Wiki</a> ]
</div>
<br />
</div>

<br />

<div align="center">
<h3 style="margin-bottom: 0;">
<img src="./_docs/quickshell/logo.svg" width="36px" style="vertical-align: top; margin-right: 5px" /><br />
Noctalia</h3>
<div style="margin-top: 0; font-size: 0.9em;">
A Quickshell-based shell layer shared across all Wayland compositors&nbsp;&nbsp;&nbsp;[ <a href="https://quickshell.outfoxxed.me">Quickshell</a> ]
</div>
<div style="margin-top: 0.4em; font-size: 0.85em; color: #888;">
Handles the bar, launcher, notifications, lock screen, session management, screenshots, and wallpapers.
Compositor configs delegate all shell functionality to Noctalia via IPC rather than bundling their own tools.
</div>
<br />
</div>

## Usage

```bash
git clone https://gitlab.com/wd2nf8gqct/dotfiles.di.git ~/.dotfiles.di
cd ~/.dotfiles.di
```

Stow a specific desktop interface:

```bash
stow niri
stow hyprland
stow sway
stow gnome
```

For full machine setup — package installation, hardware configuration, and bootstrapping — see [dotfiles.bootstrap](https://gitlab.com/wd2nf8gqct/dotfiles.bootstrap).

## Repository layout

Each top-level directory is a collection of stow packages. Each sub-directory within it
is an independent stow package targeting `~/.config` (or `~/` for systemd and bin).

```
.
├── gnome/              # GNOME shell config and extensions
├── hyprland/
│   ├── bin/            # start-hypr launcher script
│   ├── hypr/           # Hyprland + hypridle + hyprlock config
│   ├── kvantum/        # Kvantum theme
│   ├── qt5ct/          # Qt5 theme
│   ├── gtk-2.0/
│   ├── gtk-3.0/
│   ├── gtk-4.0/
│   └── systemd/        # idle.service (hypridle)
├── niri/
│   ├── bin/            # start-niri launcher script
│   ├── hypr/           # hypridle + hyprlock config
│   ├── niri/           # Niri compositor config
│   ├── swappy/         # screenshot annotation config
│   ├── gtk-3.0/
│   ├── gtk-4.0/
│   ├── systemd/        # idle.service (hypridle)
│   └── xdg/            # mimeapps.list
├── quickshell/         # Noctalia shell layer config
└── sway/
    ├── bin/            # start-sway launcher script
    ├── hypr/           # hypridle config
    ├── kanshi/         # output management config
    ├── swappy/         # screenshot annotation config
    ├── sway/           # Sway compositor config
    ├── gtk-3.0/
    ├── gtk-4.0/
    ├── systemd/        # idle.service (hypridle)
    └── swaynag/        # swaynag dialog config
```

## License

BSD 3-Clause License. See [LICENSE](LICENSE) file.
