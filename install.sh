#!/usr/bin/env bash

set -eu

BOLD="\033[1m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
MAGENTA="\033[35m"
NC="\033[0m"

# Catppuccin Mocha palette
readonly MAUVE='\033[38;2;203;166;247m'
readonly TEAL='\033[38;2;148;226;213m'
readonly TEXT='\033[38;2;205;214;244m'

function print_info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
function print_success() { echo -e "${GREEN}[OK]${NC} $*"; }
function print_warning() { echo -e "${YELLOW}[WARN]${NC} $*" >&2; }
function print_error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }
function print_step()    { echo -e "${MAUVE}==>${NC} $*"; }
function print_dry_run() { echo -e "${TEAL}[DRY-RUN]${NC} $*"; }

BASEDIR="${HOME}/.dotfiles.di"
PACKAGES_YAML="${BASEDIR}/packages.yaml"

# Global variable to track PaperWM selection
use_paperwm="false"

# Global variable to track Quickshell selection
use_quickshell="false"

# Function: clone_repository
# Description: Clones the dotfiles repository if it doesn't exist.
function clone_repository() {
    if [[ ! -d "${BASEDIR}" ]]; then
        echo -e "\n${BLUE}Cloning ${BOLD}${MAGENTA}dotfiles.di${NC}${BLUE} to ${BOLD}${MAGENTA}${BASEDIR}${NC}${BLUE}...${GREEN}"
        git clone -j 5 --recurse-submodules "https://gitlab.com/wd2nf8gqct/dotfiles.di.git" "${BASEDIR}"
    fi
}

# Function: detect_distro
# Description: Detects the Linux distribution of the current system.
function detect_distro() {
    if [[ -f "/etc/os-release" ]]; then
        source "/etc/os-release"
        case "${ID}" in
            arch|ubuntu)
                echo "${ID}"
                ;;
            fedora|opensuse-tumbleweed)
                echo "legacy"
                ;;
            *)
                echo "unsupported"
                ;;
        esac
    else
        echo "unknown"
    fi
}

# Function: detect_hardware
# Description: Detects the hardware model of the current system.
function detect_hardware() {
    if ! command -v dmidecode &>/dev/null; then
        echo "unknown"
        return
    fi
    local system_version
    local system_product
    system_version=$(sudo dmidecode -s system-version)
    system_product=$(sudo dmidecode -s system-product-name)
    if [[ "${system_version}" == "ThinkPad T480s" ]]; then
        echo "ThinkPad T480s"
    elif [[ "${system_product}" == *"ROG"* ]]; then
        echo "ROG"
    elif [[ "${system_product}" == "XPS 13 9350" ]]; then
        echo "XPS 13 9350"
    else
        echo "unknown"
    fi
}

# Function: get_package_name
# Description: Retrieves the package name for the defined distro, considering any exceptions defined in "packages.yaml".
function get_package_name() {
    local package="${1}"
    local distro="${2}"
    local package_name="${package}"
    local exception
    exception=$(yq -e ".exceptions.${distro}.[] | select(has(\"${package}\")) | .\"${package}\"" "${PACKAGES_YAML}" 2>/dev/null)
    if [[ -n "${exception}" && "${exception}" != "null" ]]; then
        package_name="${exception}"
    fi
    echo "${package_name}"
}

# Function: install_package
# Description: Installs a specified package using the appropriate package manager for the distribution.
function install_package() {
    local package="${1}"
    local distro="${2}"
    local package_name
    package_name=$(get_package_name "${package}" "${distro}")
    package_name="${package_name//\"/}"
    if [[ "${package_name}" == "skip" ]]; then
        return
    fi
    echo -e "\n${MAGENTA}Installing ${BOLD}${package_name}${NC}"
    case "${distro}" in
        arch)
            yay -S --noconfirm ${package_name}
            ;;
        ubuntu)
            sudo apt-get install -y ${package_name}
            ;;
        *)
            echo "Unsupported distribution: ${distro}"
            ;;
    esac
}

# Function: select_desktop_interface
# Description: Prompts the user to select a desktop configuration to apply.
#              On Ubuntu, GNOME is already present so we ask how to configure it
#              rather than asking whether to "install" a desktop. On Arch, presents
#              the full list of available desktop interfaces from packages.yaml.
function select_desktop_interface() {
    local __choice=$1

    local distro
    distro=$(detect_distro)

    if [[ "${distro}" == "ubuntu" ]]; then
        clone_repository
        # Ubuntu ships with GNOME — we are configuring it, not installing a DE.
        echo -e "\n${BLUE}${BOLD}How would you like to configure your desktop?${NC}"
        echo -e "${BLUE}Ubuntu includes GNOME by default.${NC}"
        select de in "Configure GNOME (+ optional PaperWM)" "Install Niri (Wayland compositor)" "Skip"; do
            case "${de}" in
                "Configure GNOME (+ optional PaperWM)")
                    eval "${__choice}"="gnome"
                    echo -e "\n${BLUE}${BOLD}Would you like to install PaperWM?${NC}"
                    select pw_choice in "Yes" "No"; do
                        case "${pw_choice}" in
                            "Yes")  use_paperwm="true";  return ;;
                            "No")   use_paperwm="false"; return ;;
                            *)      echo -e "\n${RED}Invalid option. Please try again.${NC}\n" ;;
                        esac
                    done
                    ;;
                "Install Niri (Wayland compositor)")
                    eval "${__choice}"="niri"
                    echo -e "\n${BLUE}${BOLD}Would you like to use Quickshell (Noctalia) as your desktop shell?${NC}"
                    echo -e "${BLUE}This replaces waybar, swaync, and other individual tools.${NC}"
                    select qs_choice in "Yes" "No"; do
                        case "${qs_choice}" in
                            "Yes")  use_quickshell="true";  return ;;
                            "No")   use_quickshell="false"; return ;;
                            *)      echo -e "\n${RED}Invalid option. Please try again.${NC}\n" ;;
                        esac
                    done
                    ;;
                "Skip")
                    printf "\nSkipping desktop configuration.\n"
                    exit
                    ;;
                *)
                    echo -e "\n${RED}Invalid option. Please try again.${NC}\n"
                    ;;
            esac
        done
    else
        echo -e "\n${BLUE}${BOLD}Do you want to install a desktop interface?${NC}"
        select choice in "Yes" "No"; do
            case $choice in
                "Yes")
                    clone_repository
                    echo -e "\n${BLUE}${BOLD}Please select a desktop interface:${NC}"
                    local options
                    mapfile -t options < <(yq -e '.desktop_packages | keys | .[]' "${PACKAGES_YAML}" 2>/dev/null | tr -d '"')
                    select de in "${options[@]}"; do
                        if [[ -n "$de" ]]; then
                            eval "$__choice"="$de"
                            if [[ "${de}" == "gnome" ]]; then
                                echo -e "\n${BLUE}${BOLD}Would you like to install PaperWM?${NC}"
                                select pw_choice in "Yes" "No"; do
                                    case "${pw_choice}" in
                                        "Yes")  use_paperwm="true";  return ;;
                                        "No")   use_paperwm="false"; return ;;
                                        *)      echo -e "\n${RED}Invalid option. Please try again.${NC}\n" ;;
                                    esac
                                done
                            elif [[ "${de}" == "niri" ]]; then
                                echo -e "\n${BLUE}${BOLD}Would you like to use Quickshell (Noctalia) as your desktop shell?${NC}"
                                echo -e "${BLUE}This replaces waybar, swaync, and other individual tools.${NC}"
                                select qs_choice in "Yes" "No"; do
                                    case "${qs_choice}" in
                                        "Yes")  use_quickshell="true";  return ;;
                                        "No")   use_quickshell="false"; return ;;
                                        *)      echo -e "\n${RED}Invalid option. Please try again.${NC}\n" ;;
                                    esac
                                done
                            fi
                            return
                        else
                            echo -e "\n${RED}Invalid option. Please try again.${NC}\n"
                        fi
                    done
                    ;;
                "No")
                    printf "\nSkipping desktop interface installation.\n"
                    exit
                    ;;
                *)
                    echo -e "\n${RED}Invalid option. Please try again.${NC}\n"
                    ;;
            esac
        done
    fi
}

# Function: install_dependencies
# Description: Installs necessary dependencies for the installation process.
function install_dependencies() {
    local distro
    declare -A dependencies
    dependencies=(
        ["git"]="git"
        ["yq"]="yq"
        ["stow"]="stow"
        ["rustc"]="rustc"
        ["gcc-c++"]="g++"
        ["cmake"]="cmake"
        ["meson"]="meson"
    )
    distro="$(detect_distro)"
    for dep in "${!dependencies[@]}"; do
        if ! command -v "${dependencies[$dep]}" &>/dev/null; then
            if [[ "${dep}" == "rustc" ]]; then
                curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
                . "${HOME}/.cargo/env"
                rustup default stable
            else
                install_package "${dep}" "${distro}"
            fi
        fi
    done
}

# Function: install_local_pkgbuilds
# Description: Builds and installs local PKGBUILDs from pkgbuilds/ whose name
#              matches a package in the active DE's package list. Arch-only.
function install_local_pkgbuilds() {
    local distro="${1}"
    local desktop_interface="${2}"
    local pkgbuilds_dir="${BASEDIR}/pkgbuilds"

    [[ "${distro}" != "arch" ]] && return 0
    [[ -d "${pkgbuilds_dir}" ]] || return 0

    # Collect the full package list: common + DE-specific
    mapfile -t active_packages < <(
        yq -e ".packages[]" "${PACKAGES_YAML}" 2>/dev/null
        yq -e ".desktop_packages.${desktop_interface}[]" "${PACKAGES_YAML}" 2>/dev/null
    )

    for pkgbuild_dir in "${pkgbuilds_dir}"/*/; do
        local pkg_name
        pkg_name=$(basename "${pkgbuild_dir}")

        # Only build if this package is in the active package list
        local match="false"
        for pkg in "${active_packages[@]}"; do
            if [[ "${pkg//\"/}" == "${pkg_name}" ]]; then
                match="true"
                break
            fi
        done
        [[ "${match}" == "false" ]] && continue

        if pacman -Qi "${pkg_name}" &>/dev/null; then
            echo -e "\n${YELLOW}Local package ${BOLD}${pkg_name}${NC}${YELLOW} already installed, skipping${NC}"
        else
            echo -e "\n${MAGENTA}Building local PKGBUILD: ${BOLD}${pkg_name}${NC}"
            (cd "${pkgbuild_dir}" && makepkg -si --noconfirm)
        fi
    done
}

# Function: install_packages
# Description: Installs packages defined in the "packages.yaml" file.
function install_packages() {
    local distro
    distro="$(detect_distro)"
    mapfile -t packages < <(yq -e ".packages[]" "${PACKAGES_YAML}" 2>/dev/null)
    packages=("${packages[@]//\"/}")
    for package in "${packages[@]}"; do
        install_package "${package}" "${distro}"
    done
}

# Function: install_desktop_packages
# Description: Installs packages specific to the selected desktop interface.
function install_desktop_packages() {
    local distro
    local desktop_interface
    distro="${1}"
    desktop_interface="${2}"
    mapfile -t packages < <(yq -e ".desktop_packages.${desktop_interface}[]" "${PACKAGES_YAML}" 2>/dev/null)
    packages=("${packages[@]//\"/}")

    # Load quickshell manifest replaces list for filtering
    local qs_replaces=()
    if [[ "${use_quickshell}" == "true" ]]; then
        mapfile -t qs_replaces < <(yq -e ".replaces[]" "${BASEDIR}/quickshell/manifest.json" 2>/dev/null)
    fi

    for package in "${packages[@]}"; do
        # Skip packages that quickshell replaces
        if [[ "${use_quickshell}" == "true" ]]; then
            local skip="false"
            for replaced in "${qs_replaces[@]}"; do
                if [[ "${package}" == "${replaced}" ]]; then
                    skip="true"
                    break
                fi
            done
            [[ "${skip}" == "true" ]] && continue
        fi
        install_package "${package}" "${distro}"
    done

    # Install quickshell-specific packages
    if [[ "${use_quickshell}" == "true" ]]; then
        mapfile -t qs_packages < <(yq -e ".desktop_packages.quickshell[]" "${PACKAGES_YAML}" 2>/dev/null)
        qs_packages=("${qs_packages[@]//\"/}")
        for package in "${qs_packages[@]}"; do
            install_package "${package}" "${distro}"
        done
    fi
}

# Function: configure_pre_install
# Description: Performs distribution-specific configurations prior to installing packages.
function configure_pre_install() {
    local distro
    local desktop_interface
    distro="${1}"
    desktop_interface="${2}"
    case "${desktop_interface}" in
        "gnome")
            echo -e "\n${BLUE}Creating directory: ${BOLD}${HOME}/.local/share/gnome-shell${NC}"
            mkdir -p "${HOME}/.local/share/gnome-shell"
            ;;
        "hyprland" | "niri" | "sway")
            if [[ "${desktop_interface}" == "sway" ]]; then
                echo -e "\n${MAGENTA}Installing ${BOLD}swaysome${NC}"
                cargo install --locked --root "${HOME}" swaysome
            fi
            if [[ "${distro}" == "ubuntu" && "${desktop_interface}" == "niri" ]]; then
                install_niri_stack_ubuntu
            fi
            ;;
        *)
            echo -e "\n${RED}Unsupported desktop interface: ${BOLD}${desktop_interface}${NC}"
            ;;
    esac
}

# Function: generate_autostart
# Description: Generates a compositor-specific autostart.sh with either
#              quickshell or default shell tools based on use_quickshell.
function generate_autostart() {
    local compositor="${1}"
    local config_dir="${HOME}/.config/${compositor}"
    local script="${config_dir}/autostart.sh"

    mkdir -p "${config_dir}"

    {
        echo '#!/usr/bin/env bash'
        echo 'set -euo pipefail'
        echo ''

        echo '# Compositor-specific'
        case "${compositor}" in
            "hypr")
                echo '/usr/bin/lxqt-policykit-agent &'
                echo "${HOME}/.config/hypr/scripts/xdg_portal_hyprland.sh &"
                echo 'hypridle &'
                echo "${HOME}/.config/hypr/scripts/monitor_hotplug.sh &"
                ;;
            "niri")
                echo '/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &'
                echo '/usr/lib/xdg-desktop-portal-gtk &'
                if [[ \"${use_quickshell}\" != \"true\" ]]; then
                    echo 'hypridle &'
                fi
                echo 'xwayland-satellite &'
                ;;
            "sway")
                echo 'lxqt-policykit-agent &'
                echo '/usr/bin/xdg-user-dirs-update &'
                echo '/usr/libexec/sway-systemd/wait-sni-ready && systemctl --user start sway-xdg-autostart.target'
                cat << 'SWAYIDLE'
swayidle -w \
    timeout 30 'original=$(brightnessctl g); brightnessctl set $(( original / 2 )); echo $original > /tmp/original_brightness' \
        resume 'brightnessctl set $(cat /tmp/original_brightness); rm /tmp/original_brightness' \
    timeout 300 'swaylock -f' \
    timeout 360 'swaymsg "output * power off"' \
        resume 'swaymsg "output * power on"' \
    timeout 60 'pgrep -xu "$USER" swaylock >/dev/null && swaymsg "output * power off"' \
        resume 'pgrep -xu "$USER" swaylock >/dev/null && swaymsg "output * power on"' \
    before-sleep 'swaylock -f' \
    lock 'swaylock -f' \
    unlock 'pkill -xu "$USER" -SIGUSR1 swaylock' &
SWAYIDLE
                ;;
        esac

        echo ''
        echo '# Shell'
        if [[ "${use_quickshell}" == "true" ]]; then
            echo "qs -p ${BASEDIR}/quickshell/noctalia-shell &"
        else
            case "${compositor}" in
                "hypr")
                    echo "${HOME}/.config/hypr/scripts/waybar.sh &"
                    echo "swaync &"
                    echo 'wlsunset -l 40.7 -L -74.0 -t 5000 &'
                    echo 'wl-paste --type text --watch cliphist store &'
                    echo 'wl-paste --type image --watch cliphist store &'
                    ;;
                "niri")
                    echo 'swww-daemon &'
                    echo 'waybar &'
                    echo 'swaync &'
                    echo 'wlsunset -l 40.7 -L -74.0 -t 5000 &'
                    echo 'wl-paste --type text --watch cliphist store &'
                    echo 'wl-paste --type image --watch cliphist store &'
                    ;;
                "sway")
                    echo 'waybar &'
                    echo 'swaync &'
                    ;;
            esac
        fi
    } > "${script}"

    chmod +x "${script}"
    echo -e "\n${GREEN}Generated autostart script: ${script}${NC}"
}

# Function: install_colloid_catppuccin
# Description: Installs Colloid GTK and icon themes with all Catppuccin color variants, sets GNOME theme preferences, and cleans up.
function install_colloid_catppuccin() {
    local GTK_REPO="https://github.com/vinceliuice/Colloid-gtk-theme.git"
    local ICON_REPO="https://github.com/vinceliuice/Colloid-icon-theme.git"
    local GTK_DIR="/tmp/Colloid-gtk-theme"
    local ICON_DIR="/tmp/Colloid-icon-theme"
    rm -rf "${GTK_DIR}" "${ICON_DIR}"
    trap 'rm -rf "${GTK_DIR}" "${ICON_DIR}"' EXIT
    git clone --depth=1 "${GTK_REPO}" "${GTK_DIR}" >/dev/null 2>&1
    git clone --depth=1 "${ICON_REPO}" "${ICON_DIR}" >/dev/null 2>&1
    cd "${GTK_DIR}" || exit
    ./install.sh --tweaks catppuccin -t all -s standard compact -c dark -l fixed | while IFS= read -r line; do
        if [[ "$line" == *"Installing"* ]]; then
            echo -e "${GREEN}${line}${NC}"
        elif [[ "$line" == *"ERROR"* ]]; then
            echo -e "${RED}${line}${NC}"
        elif [[ "$line" == *"Cloning"* ]]; then
            echo -e "${BLUE}${line}${NC}"
        else
            echo -e "${NC}${line}${NC}"
        fi
    done
    cd "${ICON_DIR}" || exit
    ./install.sh -s catppuccin -t all | while IFS= read -r line; do
        if [[ "$line" == *"Installing"* ]]; then
            echo -e "${GREEN}${line}${NC}"
        elif [[ "$line" == *"ERROR"* ]]; then
            echo -e "${RED}${line}${NC}"
        elif [[ "$line" == *"Cloning"* ]]; then
            echo -e "${BLUE}${line}${NC}"
        else
            echo -e "${NC}${line}${NC}"
        fi
    done
    gsettings set org.gnome.desktop.interface gtk-theme "Colloid-Purple-Dark-Compact-Catppuccin"
    gsettings set org.gnome.desktop.interface icon-theme "Colloid-Purple-Catppuccin-Dark"
    gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
    rm -rf "${GTK_DIR}" "${ICON_DIR}"
    trap - EXIT
}

# Function: configure_catppuccin_gtk
# Description: Links Catppuccin Mocha Lavender GTK4 theme files and applies GNOME settings.
function configure_catppuccin_gtk() {
    local THEME_DIR="/usr/share/themes/catppuccin-mocha-lavender-standard+default/gtk-4.0"
    local GTK4_CONFIG="${HOME}/.config/gtk-4.0"

    print_step "Applying Catppuccin Mocha Lavender GTK4 theme..."

    mkdir -p "${GTK4_CONFIG}"
    ln -sf "${THEME_DIR}/gtk.css"      "${GTK4_CONFIG}/gtk.css"
    ln -sf "${THEME_DIR}/gtk-dark.css" "${GTK4_CONFIG}/gtk-dark.css"
    ln -sf "${THEME_DIR}/assets"       "${GTK4_CONFIG}/assets"

    gsettings set org.gnome.desktop.interface gtk-theme      "catppuccin-mocha-lavender-standard+default" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface color-scheme   "prefer-dark" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface icon-theme     "Papirus-Dark" 2>/dev/null || true

    print_success "GTK4 Catppuccin theme applied."
}

# Function: install_paperwm
# Description: Installs the PaperWM GNOME Shell extension.
function install_paperwm() {
    local EXT_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/gnome-shell/extensions/paperwm@hedning:matrix.org"
    if [[ ! -d "${EXT_DIR}" ]]; then
        echo -e "\n${BLUE}Cloning PaperWM extension...${NC}"
        git clone --depth=1 https://github.com/paperwm/PaperWM.git "${EXT_DIR}"
    fi
    echo -e "\n${BLUE}Installing PaperWM...${NC}"
    (cd "${EXT_DIR}" && ./install.sh)
    echo -e "\n${GREEN}PaperWM installed and enabled.${NC}"
}

# Function: detect_hidpi_screen
# Description: Detects if the system has a HiDPI screen and recommends scaling
# Returns: Recommended scale factor (100, 125, 150, 175, 200) or empty if detection fails
function detect_hidpi_screen() {
    if ! command -v xrandr &>/dev/null; then
        echo ""
        return
    fi

    local output
    output=$(xrandr --current 2>/dev/null | grep " connected primary" | head -1)
    if [[ -z "${output}" ]]; then
        output=$(xrandr --current 2>/dev/null | grep " connected" | head -1)
    fi

    if [[ -z "${output}" ]]; then
        echo ""
        return
    fi

    local resolution
    local physical_width
    resolution=$(echo "${output}" | grep -oP '\d+x\d+' | head -1)
    physical_width=$(echo "${output}" | grep -oP '\d+mm x \d+mm' | head -1 | cut -d'x' -f1 | grep -oP '\d+')

    if [[ -z "${resolution}" ]] || [[ -z "${physical_width}" ]]; then
        echo ""
        return
    fi

    local width_px
    width_px=$(echo "${resolution}" | cut -d'x' -f1)
    local width_mm="${physical_width}"
    local width_inches
    width_inches=$(echo "scale=2; ${width_mm} / 25.4" | bc)
    local dpi
    dpi=$(echo "scale=0; ${width_px} / ${width_inches}" | bc)

    if [[ ${dpi} -ge 180 ]]; then
        echo "200"
    elif [[ ${dpi} -ge 160 ]]; then
        echo "175"
    elif [[ ${dpi} -ge 140 ]]; then
        echo "150"
    elif [[ ${dpi} -ge 110 ]]; then
        echo "125"
    else
        echo "100"
    fi
}

# Function: find_systemd_boot_entries
# Description: Returns the systemd-boot loader entries directory if systemd-boot
#              is installed, regardless of where the ESP is mounted.
#              Checks via bootctl first, then falls back to common mount points.
function find_systemd_boot_entries() {
    local esp=""
    if command -v bootctl &>/dev/null && bootctl is-installed &>/dev/null; then
        esp=$(bootctl --print-esp-path 2>/dev/null)
    fi
    if [[ -z "${esp}" ]]; then
        for mount_point in /boot /efi /boot/efi; do
            if [[ -d "${mount_point}/loader/entries" ]]; then
                esp="${mount_point}"
                break
            fi
        done
    fi
    if [[ -n "${esp}" && -d "${esp}/loader/entries" ]]; then
        echo "${esp}/loader/entries"
    fi
}

# Function: install_hyprland_suite
# Description: Installs Hyprland and related components on Ubuntu via the official installer.
# Parameters: List of hyprland components to install (e.g. hyprland hypridle hyprlock hyprpaper)
function install_hyprland_suite() {
    local components=("$@")
    echo -e "\n${BLUE}Installing Hyprland suite on Ubuntu: ${components[*]}${NC}"
    if ! command -v Hyprland &>/dev/null; then
        curl -sSL https://raw.githubusercontent.com/JaKooLit/Ubuntu-Hyprland/main/install.sh \
            | bash -s -- --quiet
    else
        echo -e "\n${YELLOW}Hyprland already installed, skipping suite install${NC}"
    fi
}

# ─── Ubuntu Niri Stack ───────────────────────────────────────────────────────

# Function: install_niri_build_deps_ubuntu
# Description: Installs system packages required to build the niri stack from source.
function install_niri_build_deps_ubuntu() {
    echo -e "\n${BLUE}Installing niri stack build dependencies...${NC}"
    sudo apt-get update -y
    # --allow-downgrades handles the case where Ubuntu security patches have
    # bumped runtime lib versions (e.g. libbz2, libdrm) but the corresponding
    # -dev packages still require the exact older version and no updated -dev
    # packages are available yet. dist-upgrade cannot help when the fix isn't
    # published; --allow-downgrades lets apt satisfy the strict = deps by
    # temporarily pinning the runtimes to what -dev packages expect.
    sudo apt-get install -y --allow-downgrades \
        build-essential cmake meson ninja-build pkg-config git \
        libwayland-dev libxkbcommon-dev libinput-dev libudev-dev \
        libgbm-dev libdrm-dev libseat-dev libegl-dev libgles-dev \
        libdbus-1-dev libsystemd-dev libpipewire-0.3-dev \
        libpango1.0-dev libpangocairo-1.0-0 libdisplay-info-dev libclang-dev \
        wayland-protocols libgdk-pixbuf2.0-dev libpam0g-dev \
        libgtk-3-dev libgtk-layer-shell-dev libgee-0.8-dev \
        libjson-glib-dev libhandy-1-dev valac scdoc \
        libx11-dev libxcb1-dev libxcb-shape0-dev libxcb-render0-dev \
        unzip python3-pip golang-go
}

# Function: build_niri_ubuntu
# Description: Builds and installs niri via cargo, and registers its session file.
function build_niri_ubuntu() {
    if command -v niri &>/dev/null; then
        echo -e "\n${YELLOW}niri already installed, skipping${NC}"
        return
    fi
    echo -e "\n${MAGENTA}Installing ${BOLD}niri${NC}"
    cargo install --locked niri
    local session_dir="/usr/share/wayland-sessions"
    sudo mkdir -p "${session_dir}"
    if [[ ! -f "${session_dir}/niri.desktop" ]]; then
        printf '[Desktop Entry]\nName=Niri\nComment=A scrollable-tiling Wayland compositor\nExec=niri-session\nType=Application\n' \
            | sudo tee "${session_dir}/niri.desktop" > /dev/null
    fi
}

# Function: build_swaync_ubuntu
# Description: Builds and installs SwayNotificationCenter from source.
function build_swaync_ubuntu() {
    if command -v swaync &>/dev/null; then
        echo -e "\n${YELLOW}swaync already installed, skipping${NC}"
        return
    fi
    echo -e "\n${MAGENTA}Installing ${BOLD}swaync${NC}"
    local build_dir="/tmp/swaync-build"
    rm -rf "${build_dir}"
    git clone --depth=1 https://github.com/ErikReider/SwayNotificationCenter.git "${build_dir}"
    cd "${build_dir}"
    meson setup build --prefix=/usr
    ninja -C build
    sudo ninja -C build install
    cd -
    rm -rf "${build_dir}"
}

# Function: build_swaylock_effects_ubuntu
# Description: Builds and installs swaylock-effects from source.
function build_swaylock_effects_ubuntu() {
    if command -v swaylock &>/dev/null; then
        echo -e "\n${YELLOW}swaylock already installed, skipping${NC}"
        return
    fi
    echo -e "\n${MAGENTA}Installing ${BOLD}swaylock-effects${NC}"
    local build_dir="/tmp/swaylock-effects-build"
    rm -rf "${build_dir}"
    git clone --depth=1 https://github.com/mortie/swaylock-effects.git "${build_dir}"
    cd "${build_dir}"
    meson setup build --prefix=/usr
    ninja -C build
    sudo ninja -C build install
    if [[ ! -f /etc/pam.d/swaylock ]]; then
        echo "auth include login" | sudo tee /etc/pam.d/swaylock > /dev/null
    fi
    cd -
    rm -rf "${build_dir}"
}

# Function: build_xwayland_satellite_ubuntu
# Description: Builds and installs xwayland-satellite via cargo.
function build_xwayland_satellite_ubuntu() {
    if command -v xwayland-satellite &>/dev/null; then
        echo -e "\n${YELLOW}xwayland-satellite already installed, skipping${NC}"
        return
    fi
    echo -e "\n${MAGENTA}Installing ${BOLD}xwayland-satellite${NC}"
    cargo install --locked xwayland-satellite
}

# Function: build_hypridle_ubuntu
# Description: Builds and installs hypridle from source using cmake.
function build_hypridle_ubuntu() {
    if command -v hypridle &>/dev/null; then
        echo -e "\n${YELLOW}hypridle already installed, skipping${NC}"
        return
    fi
    echo -e "\n${MAGENTA}Installing ${BOLD}hypridle${NC}"
    local build_dir="/tmp/hypridle-build"
    rm -rf "${build_dir}"
    git clone --depth=1 https://github.com/hyprwm/hypridle.git "${build_dir}"
    cd "${build_dir}"
    cmake -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr
    cmake --build build
    sudo cmake --install build
    cd -
    rm -rf "${build_dir}"
}

# Function: build_wlsunset_ubuntu
# Description: Builds and installs wlsunset from source.
function build_wlsunset_ubuntu() {
    if command -v wlsunset &>/dev/null; then
        echo -e "\n${YELLOW}wlsunset already installed, skipping${NC}"
        return
    fi
    echo -e "\n${MAGENTA}Installing ${BOLD}wlsunset${NC}"
    local build_dir="/tmp/wlsunset-build"
    rm -rf "${build_dir}"
    git clone --depth=1 https://git.sr.ht/~kennylevinsen/wlsunset "${build_dir}"
    cd "${build_dir}"
    meson setup build --prefix=/usr
    ninja -C build
    sudo ninja -C build install
    cd -
    rm -rf "${build_dir}"
}

# Function: install_swww_ubuntu
# Description: Installs swww from GitHub releases (pre-built static binary).
function install_swww_ubuntu() {
    if command -v swww &>/dev/null; then
        echo -e "\n${YELLOW}swww already installed, skipping${NC}"
        return
    fi
    echo -e "\n${MAGENTA}Installing ${BOLD}swww${NC}"
    local latest_tag
    latest_tag=$(curl -s https://api.github.com/repos/LGFae/swww/releases/latest | grep '"tag_name"' | cut -d '"' -f4)
    local tmp_dir
    tmp_dir=$(mktemp -d)
    curl -L "https://github.com/LGFae/swww/releases/download/${latest_tag}/swww-x86_64-unknown-linux-musl.tar.gz" \
        | tar xz -C "${tmp_dir}"
    sudo install -m 755 "${tmp_dir}/swww" /usr/local/bin/swww
    sudo install -m 755 "${tmp_dir}/swww-daemon" /usr/local/bin/swww-daemon
    rm -rf "${tmp_dir}"
}

# Function: install_cliphist_ubuntu
# Description: Installs cliphist via go install.
function install_cliphist_ubuntu() {
    if command -v cliphist &>/dev/null; then
        echo -e "\n${YELLOW}cliphist already installed, skipping${NC}"
        return
    fi
    echo -e "\n${MAGENTA}Installing ${BOLD}cliphist${NC}"
    GOBIN="${HOME}/.local/bin" go install go.senan.xyz/cliphist@latest
}

# Function: install_yazi_ubuntu
# Description: Installs yazi from GitHub releases (pre-built static binary).
function install_yazi_ubuntu() {
    if command -v yazi &>/dev/null; then
        echo -e "\n${YELLOW}yazi already installed, skipping${NC}"
        return
    fi
    echo -e "\n${MAGENTA}Installing ${BOLD}yazi${NC}"
    local latest_tag
    latest_tag=$(curl -s https://api.github.com/repos/sxyazi/yazi/releases/latest | grep '"tag_name"' | cut -d '"' -f4)
    local tmp_dir
    tmp_dir=$(mktemp -d)
    curl -L "https://github.com/sxyazi/yazi/releases/download/${latest_tag}/yazi-x86_64-unknown-linux-musl.zip" \
        -o "${tmp_dir}/yazi.zip"
    unzip -q "${tmp_dir}/yazi.zip" -d "${tmp_dir}"
    sudo install -m 755 "${tmp_dir}/yazi-x86_64-unknown-linux-musl/yazi" /usr/local/bin/yazi
    sudo install -m 755 "${tmp_dir}/yazi-x86_64-unknown-linux-musl/ya" /usr/local/bin/ya
    rm -rf "${tmp_dir}"
}

# Function: install_bluetui_ubuntu
# Description: Installs bluetui via cargo.
function install_bluetui_ubuntu() {
    if command -v bluetui &>/dev/null; then
        echo -e "\n${YELLOW}bluetui already installed, skipping${NC}"
        return
    fi
    echo -e "\n${MAGENTA}Installing ${BOLD}bluetui${NC}"
    cargo install --locked --root "${HOME}" bluetui
}

# Function: install_nwg_bar_ubuntu
# Description: Installs nwg-bar via go install.
function install_nwg_bar_ubuntu() {
    if command -v nwg-bar &>/dev/null; then
        echo -e "\n${YELLOW}nwg-bar already installed, skipping${NC}"
        return
    fi
    echo -e "\n${MAGENTA}Installing ${BOLD}nwg-bar${NC}"
    GOBIN="${HOME}/.local/bin" go install github.com/nwg-piotr/nwg-bar@latest
}

# Function: install_dart_sass_ubuntu
# Description: Installs dart-sass binary from GitHub releases.
function install_dart_sass_ubuntu() {
    if command -v sass &>/dev/null; then
        echo -e "\n${YELLOW}dart-sass already installed, skipping${NC}"
        return
    fi
    echo -e "\n${MAGENTA}Installing ${BOLD}dart-sass${NC}"
    local latest_tag
    latest_tag=$(curl -s https://api.github.com/repos/sass/dart-sass/releases/latest | grep '"tag_name"' | cut -d '"' -f4)
    local tmp_dir
    tmp_dir=$(mktemp -d)
    curl -L "https://github.com/sass/dart-sass/releases/download/${latest_tag}/dart-sass-${latest_tag}-linux-x64.tar.gz" \
        | tar xz -C "${tmp_dir}"
    sudo install -m 755 "${tmp_dir}/dart-sass/sass" /usr/local/bin/sass
    rm -rf "${tmp_dir}"
}

# Function: install_catppuccin_gtk_ubuntu
# Description: Installs Catppuccin Mocha Lavender GTK theme from source to /usr/share/themes.
function install_catppuccin_gtk_ubuntu() {
    local theme_dir="/usr/share/themes/catppuccin-mocha-lavender-standard+default"
    if [[ -d "${theme_dir}" ]]; then
        echo -e "\n${YELLOW}catppuccin-gtk-theme-mocha already installed, skipping${NC}"
        return
    fi
    echo -e "\n${MAGENTA}Installing ${BOLD}catppuccin-gtk-theme-mocha${NC}"
    local build_dir="/tmp/catppuccin-gtk-build"
    rm -rf "${build_dir}"
    git clone --depth=1 https://github.com/catppuccin/gtk.git "${build_dir}"
    cd "${build_dir}"
    pip3 install --quiet --user -r requirements.txt
    sudo python3 install.py mocha lavender --dest /usr/share/themes
    cd -
    rm -rf "${build_dir}"
}

# Function: install_papirus_catppuccin_ubuntu
# Description: Installs Catppuccin Papirus folder icons from source.
function install_papirus_catppuccin_ubuntu() {
    if [[ -f "/usr/share/icons/Papirus-Dark/places/22/folder-mocha-lavender.svg" ]]; then
        echo -e "\n${YELLOW}papirus-folders-catppuccin already installed, skipping${NC}"
        return
    fi
    echo -e "\n${MAGENTA}Installing ${BOLD}papirus-folders-catppuccin${NC}"
    local build_dir="/tmp/papirus-catppuccin-build"
    rm -rf "${build_dir}"
    git clone --depth=1 https://github.com/catppuccin/papirus-folders.git "${build_dir}"
    cd "${build_dir}"
    sudo cp -r src/* /usr/share/icons/Papirus/ 2>/dev/null || true
    sudo cp -r src/* /usr/share/icons/Papirus-Dark/ 2>/dev/null || true
    sudo cp -r src/* /usr/share/icons/Papirus-Light/ 2>/dev/null || true
    papirus-folders -C cat-mocha-lavender --theme Papirus-Dark 2>/dev/null || true
    cd -
    rm -rf "${build_dir}"
}

# Function: install_pwvucontrol_ubuntu
# Description: Installs pwvucontrol via cargo.
function install_pwvucontrol_ubuntu() {
    if command -v pwvucontrol &>/dev/null; then
        echo -e "\n${YELLOW}pwvucontrol already installed, skipping${NC}"
        return
    fi
    echo -e "\n${MAGENTA}Installing ${BOLD}pwvucontrol${NC}"
    sudo apt-get install -y libpipewire-0.3-dev libgtk-4-dev libadwaita-1-dev
    cargo install --locked pwvucontrol
}

# Function: install_niri_stack_ubuntu
# Description: Installs the full niri stack on Ubuntu for packages not available via apt.
#              Called from configure_pre_install before the main package loop runs.
function install_niri_stack_ubuntu() {
    echo -e "\n${BLUE}${BOLD}Installing niri stack for Ubuntu...${NC}"
    install_niri_build_deps_ubuntu
    build_niri_ubuntu
    build_swaync_ubuntu
    build_swaylock_effects_ubuntu
    build_xwayland_satellite_ubuntu
    build_hypridle_ubuntu
    build_wlsunset_ubuntu
    install_swww_ubuntu
    install_cliphist_ubuntu
    install_yazi_ubuntu
    install_bluetui_ubuntu
    install_nwg_bar_ubuntu
    install_dart_sass_ubuntu
    install_catppuccin_gtk_ubuntu
    install_papirus_catppuccin_ubuntu
    install_pwvucontrol_ubuntu
    echo -e "\n${GREEN}${BOLD}niri stack installation complete.${NC}"
}

# Function: configure_display_wakeup
# Description: Installs udev rules that allow the system to wake from S0ix when
#              an external display is connected. Covers Thunderbolt/USB4 (USB-C
#              monitors and docks) and PCIe GPU display outputs (HDMI/DisplayPort).
#              Only meaningful if S0ix is active; harmless otherwise.
function configure_display_wakeup() {
    local rules_file="/etc/udev/rules.d/99-niri-display-wakeup.rules"

    echo -e "\n${BLUE}Configuring display hotplug wakeup sources...${NC}"

    sudo tee "${rules_file}" > /dev/null << 'EOF'
# Wake system on Thunderbolt/USB4 device connect (USB-C monitors, docks)
ACTION=="add|change", SUBSYSTEM=="thunderbolt", ATTR{power/wakeup}="enabled"

# Wake system on PCIe display controller hotplug (HDMI/DisplayPort on integrated GPU)
# Class 0x0300 = VGA-compatible, 0x0302 = 3D controller, 0x0380 = other display
ACTION=="add|change", SUBSYSTEM=="pci", ATTR{class}=="0x030000", ATTR{power/wakeup}="enabled"
ACTION=="add|change", SUBSYSTEM=="pci", ATTR{class}=="0x030200", ATTR{power/wakeup}="enabled"
ACTION=="add|change", SUBSYSTEM=="pci", ATTR{class}=="0x038000", ATTR{power/wakeup}="enabled"

# Wake system on USB device connect (USB-C hubs and display adapters)
ACTION=="add", SUBSYSTEM=="usb", ATTR{power/wakeup}="enabled"
EOF

    sudo udevadm control --reload-rules
    sudo udevadm trigger --subsystem-match=pci --subsystem-match=thunderbolt 2>/dev/null || true

    echo -e "${GREEN}Display wakeup rules installed: ${rules_file}${NC}"
}

# Function: configure_desktop_interface
# Description: Performs desktop interface configurations post installation.
function configure_desktop_interface() {
    local distro
    local desktop_interface
    local gpg_config_file
    local pinentry_line
    local scale_factor
    distro="${1}"
    desktop_interface="${2}"
    scale_factor="${3:-auto}"
    gpg_config_file="${HOME}/.gnupg/gpg-agent.conf"
    pinentry_line="pinentry-program /usr/bin/pinentry-tty"

    # Enable clamshell when docked
    echo -e "\n${BLUE}Configuring clamshell settings${NC}"
    if [[ -f "/etc/systemd/logind.conf" ]]; then
        sudo sed -i 's/^#HandleLidSwitchDocked=.*/HandleLidSwitchDocked=ignore/' /etc/systemd/logind.conf
        sudo sed -i 's/^#HandleLidSwitch=.*/HandleLidSwitch=suspend/' /etc/systemd/logind.conf
        sudo sed -i 's/^#HandleLidSwitchExternalPower=.*/HandleLidSwitchExternalPower=suspend/' /etc/systemd/logind.conf
    else
        echo -e "HandleLidSwitchExternalPower=suspend\nHandleLidSwitch=suspend\nHandleLidSwitchDocked=ignore" | sudo tee -a /etc/systemd/logind.conf > /dev/null
    fi

    # GPG to utilize pinentry-tty
    echo -e "\n${BLUE}Configuring gpg settings${NC}"
    if [[ -f "${gpg_config_file}" ]]; then
        if grep -q "^pinentry-program" "${gpg_config_file}"; then
            sed -i "s|^pinentry-program.*|${pinentry_line}|" "${gpg_config_file}"
        else
            echo "${pinentry_line}" >> "${gpg_config_file}"
        fi
    else
        echo "${pinentry_line}" > "${gpg_config_file}"
    fi
    gpg-connect-agent reloadagent /bye > /dev/null 2>&1

    case "${desktop_interface}" in
        "gnome")
            local settings_dir
            local gnome_categories
            settings_dir="${BASEDIR}/${desktop_interface}/_settings"
            gnome_categories=(
                "/org/gnome/desktop/interface/:interface.ini"
                "/org/gnome/desktop/wm/:wm.ini"
                "/org/gnome/nautilus/:nautilus.ini"
                "/org/gnome/desktop/input-sources/:input-sources.ini"
                "/org/gnome/settings-daemon/plugins/:plugins.ini"
                "/org/gnome/shell/extensions/:extensions.ini"
            )

            for category in "${gnome_categories[@]}"; do
                IFS=':' read -r dconf_path file <<< "${category}"
                if [ -f "${settings_dir}/${file}" ]; then
                    dconf load "${dconf_path}" < "${settings_dir}/${file}"
                    echo -e "\n${YELLOW}Imported ${settings_dir}/${file} to ${dconf_path}${NC}"
                else
                    echo -e "\n${RED}Warning: ${file} not found in ${settings_dir}${NC}"
                fi
            done

            echo -e "\n${BLUE}Reloading GNOME Shell extensions...${NC}"
            if command -v gdbus &> /dev/null && [[ -n "${DBUS_SESSION_BUS_ADDRESS}" ]]; then
                gdbus call --session --dest org.gnome.Shell \
                    --object-path /org/gnome/Shell \
                    --method org.gnome.Shell.Extensions.ReloadExtensions 2>/dev/null || \
                    echo -e "${YELLOW}Could not reload extensions via D-Bus (may need manual GNOME Shell restart)${NC}"
            fi

            for e in "${HOME}"/.local/share/gnome-shell/extensions/*; do
                if [[ -d "${e}" ]]; then
                    extension=$(basename "${e}")
                    gnome-extensions enable "${extension}" 2>/dev/null || \
                        echo -e "${YELLOW}Could not enable ${extension} (will be available after logout)${NC}"
                    echo -e "\n${BLUE}Enabled GNOME extension: ${BOLD}${extension}${NC}"
                fi
            done

            echo -e "\n${BLUE}${BOLD}Disabling application switching shortcuts...${NC}"
            for i in {1..9}; do
                gsettings set org.gnome.shell.keybindings switch-to-application-$i "[]"
                echo -e "${GREEN}Disabled switch-to-application-$i${NC}"
            done

            echo -e "\n${BLUE}${BOLD}Setting workspace switching to Super+number_key...${NC}"
            for i in {1..9}; do
                gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-$i "['<Super>$i']"
                echo -e "${GREEN}Set switch-to-workspace-$i to Super+$i${NC}"
            done

            echo -e "\n${BLUE}${BOLD}Setting move-to-workspace shortcuts...${NC}"
            for i in {1..9}; do
                gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-$i "['<Super><Shift>$i']"
                echo -e "${GREEN}Set move-to-workspace-$i to Super+Shift+$i${NC}"
            done

            if [[ "${distro}" == "ubuntu" ]]; then
                echo -e "\n${BLUE}${BOLD}Disabling desktop icons and dock...${NC}"
                gnome-extensions disable ding@rastersoft.com
                gnome-extensions disable "ubuntu-dock@ubuntu.com"
                echo -e "${GREEN}Disabled desktop icons and dock${NC}"
            fi

            echo -e "\n${BLUE}${BOLD}Configuring display scaling...${NC}"
            gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer']"

            local target_scale
            if [[ "${scale_factor}" == "auto" ]]; then
                local detected_scale
                detected_scale=$(detect_hidpi_screen)
                if [[ -n "${detected_scale}" && "${detected_scale}" != "100" ]]; then
                    target_scale="${detected_scale}"
                    echo -e "${YELLOW}Detected HiDPI screen, recommending ${target_scale}% scaling${NC}"
                else
                    target_scale="100"
                    echo -e "${YELLOW}Standard DPI detected, using 100% scaling${NC}"
                fi
            else
                target_scale="${scale_factor}"
                echo -e "${YELLOW}Using specified scaling: ${target_scale}%${NC}"
            fi

            if [[ "${target_scale}" != "100" ]]; then
                local scale_value
                scale_value=$(echo "scale=2; ${target_scale} / 100" | bc)
                gsettings set org.gnome.desktop.interface text-scaling-factor "${scale_value}"
                echo -e "${GREEN}Set scaling to ${target_scale}% (${scale_value})${NC}"
            else
                echo -e "${GREEN}Using default 100% scaling${NC}"
            fi

            echo -e "\n${BLUE}${BOLD}Setting wallpaper...${NC}"
            local wallpaper_file
            if [[ "${distro}" == "ubuntu" && -f "${HOME}/wallpaper_ubuntu.jpg" ]]; then
                wallpaper_file="${HOME}/wallpaper_ubuntu.jpg"
            elif [[ -f "${HOME}/wallpaper_${distro}.png" ]]; then
                wallpaper_file="${HOME}/wallpaper_${distro}.png"
            else
                echo -e "${YELLOW}Warning: Wallpaper file not found, skipping${NC}"
                wallpaper_file=""
            fi

            if [[ -n "${wallpaper_file}" ]]; then
                gsettings set org.gnome.desktop.background picture-uri "file://${wallpaper_file}"
                gsettings set org.gnome.desktop.background picture-uri-dark "file://${wallpaper_file}"
                echo -e "${GREEN}Set wallpaper to ${wallpaper_file}${NC}"
            fi

            echo -e "\n${BLUE}${BOLD}Setting user icon...${NC}"
            gdbus call --system --dest "org.freedesktop.Accounts" \
                --object-path "/org/freedesktop/Accounts/User$(id -u)" \
                --method "org.freedesktop.Accounts.User.SetIconFile" "${HOME}/avatar.png" > /dev/null || true
            echo -e "${GREEN}Set user icon to avatar.png${NC}"

            echo -e "\n${BLUE}${BOLD}Setting GTK theme...${NC}"
            gsettings set org.gnome.desktop.interface gtk-theme "Adwaita-dark"
            echo -e "${GREEN}Set GTK theme to Adwaita-dark${NC}"

            # All configuration steps completed
            echo -e "\n${YELLOW}${BOLD}All configuration steps completed.${NC}"

            if [[ "${distro}" != "ubuntu" ]]; then
                sudo systemctl set-default graphical.target
                sudo systemctl enable --now gdm
            fi

            echo -e "\n${BLUE}${BOLD}Setting Wayland as default session...${NC}"
            local gdm_config="/etc/gdm3/custom.conf"
            if [[ "${distro}" == "arch" ]]; then
                gdm_config="/etc/gdm/custom.conf"
            fi

            if [[ -f "${gdm_config}" ]]; then
                sudo sed -i 's/^#WaylandEnable=false/WaylandEnable=true/' "${gdm_config}"
                sudo sed -i 's/^WaylandEnable=false/WaylandEnable=true/' "${gdm_config}"
                echo -e "${GREEN}Enabled Wayland in GDM${NC}"
            fi

            local user_session_file="/var/lib/AccountsService/users/$(whoami)"
            if [[ -f "${user_session_file}" ]]; then
                if sudo grep -q "^XSession=" "${user_session_file}"; then
                    sudo sed -i 's/^XSession=.*/XSession=gnome/' "${user_session_file}"
                else
                    echo "XSession=gnome" | sudo tee -a "${user_session_file}" > /dev/null
                fi
                if sudo grep -q "^Session=" "${user_session_file}"; then
                    sudo sed -i 's/^Session=.*/Session=/' "${user_session_file}"
                fi
                echo -e "${GREEN}Set Wayland as default session for user${NC}"
            fi

            echo -e "\n${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e "${YELLOW}${BOLD}IMPORTANT:${NC} ${YELLOW}Please log out and log back in for all changes to take effect.${NC}"
            echo -e "${YELLOW}This includes:${NC}"
            echo -e "  ${BLUE}•${NC} GNOME Shell extensions"
            echo -e "  ${BLUE}•${NC} Keyboard shortcuts"
            echo -e "  ${BLUE}•${NC} Wallpaper and theme settings"
            echo -e "  ${BLUE}•${NC} dconf/gsettings changes"
            echo -e "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
            ;;
        "hyprland")
            if [[ "$(detect_distro)" == "ubuntu" ]]; then
                install_hyprland_suite hyprland hypridle hyprlock hyprpaper
            fi
            sudo sed -i 's/^#HandleLidSwitch=.*/HandleLidSwitch=ignore/' /etc/systemd/logind.conf
            if ! command -v "volumectl" &>/dev/null; then
                echo -e "\n${MAGENTA}Installing ${BOLD}volumectl${NC}"
                curl -L "https://github.com/vially/volumectl/releases/download/v0.1.0/volumectl" -o "${HOME}/bin/volumectl"
                chmod +x "${HOME}/bin/volumectl"
            fi
            if ! command -v "lightctl" &>/dev/null; then
                echo -e "\n${MAGENTA}Installing ${BOLD}lightctl${NC}"
                export GOBIN="${HOME}/bin"
                go install github.com/denysvitali/lightctl@latest
            fi
            if ! command -v "bluetui" &>/dev/null; then
                echo -e "\n${MAGENTA}Installing ${BOLD}bluetui${NC}"
                cargo install --locked --root "${HOME}" bluetui
            fi
            gsettings set org.gnome.desktop.interface color-scheme prefer-dark
            gsettings set org.gnome.desktop.interface gtk-theme Adwaita-dark
            ;;
        "niri")
            configure_catppuccin_gtk
            configure_display_wakeup
            if [[ "${use_quickshell}" == "true" ]]; then
                systemctl --user disable --now hypridle.service 2>/dev/null || true
            else
                systemctl --user enable --now idle.service 2>/dev/null || \
                    echo -e "\n${YELLOW}Could not enable idle.service — enable it manually after first login.${NC}"
            fi
            ;;
        "sway")
            gsettings set org.gnome.desktop.interface color-scheme prefer-dark
            gsettings set org.gnome.desktop.interface gtk-theme Adwaita-dark
            ;;
        *)
            echo -e "\n${RED}Unsupported desktop interface: ${BOLD}${desktop_interface}${NC}"
            ;;
    esac
}

# Function: configure_hardware
# Description: Performs post system setup dependant on hardware.
function configure_hardware() {
    local hardware
    local hardware_lowercase
    hardware=$(detect_hardware)
    hardware_lowercase=$(echo "${hardware}" | tr '[:upper:] ' '[:lower:]_')
    case "${hardware}" in
        "ROG") ;;
        "ThinkPad T480s") ;;
        "XPS 13 9350")
            local bluetooth_firmware_file
            local bluetooth_firmware
            bluetooth_firmware_file="BCM4350C5_003.006.007.0095.1703.hcd"
            bluetooth_firmware="BCM4350C5-0a5c-6412.hcd"
            echo -e "\n${YELLOW}Post system configuration for ${BOLD}${hardware}${NC}"
            echo -e "${BLUE}Configuring bluetooth driver${NC}"
            if [ ! -d "/lib/firmware/brcm/" ]; then
                sudo mkdir -p /lib/firmware/brcm/
            fi
            sudo cp -f "${BASEDIR}/system_components/${hardware_lowercase}/bluetooth/${bluetooth_firmware_file}" "/lib/firmware/brcm/${bluetooth_firmware}"
            ;;
    esac
}

# Function: configure_nvidia_for_niri
# Description: If Niri is selected and an Nvidia GPU is present, update kernel parameters for GRUB or systemd-boot (ignoring fallback entries).
function configure_nvidia_for_niri() {
    local desktop_interface="${1}"
    if [[ "${desktop_interface}" != "niri" ]]; then
        return
    fi
    if ! lspci | grep -i 'vga.*nvidia' &>/dev/null; then
        return
    fi
    echo -e "\n${YELLOW}Nvidia GPU detected. Configuring kernel parameters for Niri...${NC}"
    local distro
    distro="$(detect_distro)"
    local required_modules="nvidia nvidia_modeset nvidia_uvm nvidia_drm"
    if [[ "${distro}" == "ubuntu" ]]; then
        # Install NVIDIA open kernel modules via ubuntu-drivers
        if ! dpkg -l | grep -q "^ii.*nvidia-open"; then
            echo -e "\n${MAGENTA}Installing NVIDIA open kernel modules...${NC}"
            sudo apt-get install -y ubuntu-drivers-common
            sudo ubuntu-drivers install --gpgpu 2>/dev/null || sudo ubuntu-drivers autoinstall
        fi
        # Register required modules for initramfs
        local initramfs_modules="/etc/initramfs-tools/modules"
        local updated=0
        for mod in ${required_modules}; do
            if [[ -z "$(grep -w "${mod}" "${initramfs_modules}" 2>/dev/null)" ]]; then
                echo "${mod}" | sudo tee -a "${initramfs_modules}" > /dev/null
                updated=1
            fi
        done
        if [[ "${updated}" -eq 1 ]]; then
            echo -e "\n${GREEN}Updated ${initramfs_modules} with NVIDIA modules${NC}"
            sudo update-initramfs -u
        else
            echo -e "\n${GREEN}NVIDIA modules already present in initramfs config.${NC}"
        fi
    else
        install_package "nvidia-dkms" "${distro}"
        local mkinitcpio_conf="/etc/mkinitcpio.conf"
        if [[ -f "${mkinitcpio_conf}" ]]; then
            local current_modules
            current_modules=$(grep "^MODULES=" "${mkinitcpio_conf}" | sed 's/^MODULES=//' | tr -d '()')
            local updated_modules="${current_modules}"
            for mod in ${required_modules}; do
                if ! grep -qw "${mod}" <<< "${current_modules}"; then
                    updated_modules="${updated_modules} ${mod}"
                fi
            done
            updated_modules=$(echo "${updated_modules}" | xargs)
            if [[ "${updated_modules}" != "${current_modules}" ]]; then
                sudo sed -i "s|^MODULES=.*|MODULES=(${updated_modules})|" "${mkinitcpio_conf}"
                echo -e "\n${GREEN}Updated MODULES in ${mkinitcpio_conf}: (${updated_modules})${NC}"
                sudo mkinitcpio -P
            else
                echo -e "\n${GREEN}NVIDIA modules already present in mkinitcpio.conf.${NC}"
            fi
        fi
    fi
    local entries_dir
    entries_dir=$(find_systemd_boot_entries)
    if [[ -n "${entries_dir}" ]]; then
        local updated_any=0
        for entry in "${entries_dir}"/*.conf; do
            if [[ "${entry}" == *fallback* ]]; then
                continue
            fi
            if ! grep -q "nvidia-drm.modeset=1" "${entry}" || ! grep -q "nvidia-drm.fbdev=1" "${entry}"; then
                sudo sed -i '/^options / s/$/ quiet loglevel=3 rd.udev.log_level=3 nvidia-drm.modeset=1 nvidia-drm.fbdev=1/' "${entry}"
                echo -e "\n${GREEN}Appended boot flags to ${entry}${NC}"
                updated_any=1
            fi
        done
        if [[ "${updated_any}" -eq 0 ]]; then
            echo -e "\n${GREEN}Nvidia boot flags already present in all systemd-boot entries.${NC}"
        fi
    elif [[ -f /etc/default/grub ]]; then
        if ! grep -q "nvidia-drm.modeset=1" /etc/default/grub || ! grep -q "nvidia-drm.fbdev=1" /etc/default/grub; then
            sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="nvidia-drm.modeset=1 nvidia-drm.fbdev=1 /' /etc/default/grub
            echo -e "\n${GREEN}Appended boot flags to /etc/default/grub${NC}"
            sudo grub-mkconfig -o /boot/grub/grub.cfg
            echo -e "\n${GREEN}Regenerated GRUB config at /boot/grub/grub.cfg${NC}"
        else
            echo -e "\n${GREEN}Nvidia boot flags already present in /etc/default/grub.${NC}"
        fi
    fi
    echo "options nvidia-drm modeset=1 fbdev=1" | sudo tee /etc/modprobe.d/nvidia-drm.conf > /dev/null
    echo -e "\n${GREEN}Nvidia kernel modesetting and fbdev configured. Please reboot to apply changes.${NC}"
}

# Function: select_de_options
# Description: Asks DE-specific follow-up questions (PaperWM for gnome,
#              Quickshell for compositors). Called when desktop_interface is
#              provided externally (e.g. from provision.sh) so those questions
#              are still answered interactively.
function select_de_options() {
    local desktop_interface="${1}"
    if [[ "${desktop_interface}" == "gnome" ]]; then
        echo -e "\n${BLUE}${BOLD}Would you like to install PaperWM?${NC}"
        select pw_choice in "Yes" "No"; do
            case "${pw_choice}" in
                "Yes") use_paperwm="true"; return ;;
                "No")  use_paperwm="false"; return ;;
                *)     echo -e "\n${RED}Invalid option. Please try again.${NC}\n" ;;
            esac
        done
    elif [[ "${desktop_interface}" == "niri" ]]; then
        echo -e "\n${BLUE}${BOLD}Would you like to use Quickshell (Noctalia) as your desktop shell?${NC}"
        echo -e "${BLUE}This replaces waybar, swaync, and other individual tools.${NC}"
        select qs_choice in "Yes" "No"; do
            case "${qs_choice}" in
                "Yes") use_quickshell="true"; return ;;
                "No")  use_quickshell="false"; return ;;
                *)     echo -e "\n${RED}Invalid option. Please try again.${NC}\n" ;;
            esac
        done
    fi
}

# Function: main
# Description: Orchestrates the full installation and configuration process for the system.
#   - Detects the Linux distribution and validates support.
#   - Prompts the user to select a desktop interface if not provided.
#   - Clones the dotfiles repository if necessary.
#   - Installs all required dependencies and packages for the selected distribution and desktop interface.
#   - Performs pre-install configuration steps specific to the distribution and desktop environment.
#   - Installs desktop-specific packages.
#   - Applies NVIDIA-specific kernel configuration if Niri and NVIDIA GPU are detected.
#   - Stows dotfile configurations for the selected desktop interface.
#   - Applies post-install configuration for the desktop environment.
#   - Installs and enables PaperWM if selected during GNOME configuration, and disables desktop icons for PaperWM.
#   - Runs hardware-specific post-setup configuration.
# Parameters:
#   $1 - (Optional) The distribution ID (e.g., "arch", "ubuntu"). If not provided, auto-detected.
#   $2 - (Optional) The desktop interface (e.g., "gnome", "niri"). If not provided, user is prompted.
#   $3 - (Optional) DE-specific option ("quickshell" for niri, "paperwm" for gnome).
#        Skips the follow-up interactive prompt when provided.
function main() {
    local distro=${1:-$(detect_distro)}
    local desktop_interface=${2:-}
    local de_option=${3:-}

    # Apply DE-specific option flags passed as arguments
    if [[ "${de_option}" == "quickshell" ]]; then
        use_quickshell="true"
    elif [[ "${de_option}" == "paperwm" ]]; then
        use_paperwm="true"
    fi

    if [[ "${distro}" == "legacy" ]]; then
        echo -e "\n${YELLOW}This distribution is no longer supported. Please use the ${BOLD}legacy-distros${NC}${YELLOW} branch for best-effort support. No further updates will be provided for ${BOLD}${distro}${NC}${YELLOW}.${NC}"
        exit 1
    fi
    if [[ "${distro}" != "arch" && "${distro}" != "ubuntu" ]]; then
        echo -e "\n${RED}Unsupported distribution: ${distro}. Only Arch and Ubuntu are supported.${NC}"
        exit 1
    fi

    echo -e "\n${YELLOW}***************************************\n"
    echo -e "Detected distribution: ${BOLD}${distro}${NC}${YELLOW}"
    echo -e "\n***************************************${NC}"

    if [[ -z "${desktop_interface}" ]]; then
        # Full interactive path: selects DE + DE-specific options (Quickshell, PaperWM)
        select_desktop_interface desktop_interface
    else
        clone_repository
        # Only prompt for DE-specific options if not already set via argument
        if [[ -z "${de_option}" ]]; then
            select_de_options "${desktop_interface}"
        fi
    fi

    echo -e "\n${YELLOW}Preparing to install ${BOLD}${desktop_interface}${NC}${YELLOW} on ${BOLD}${distro}${NC}${YELLOW}..."
    install_dependencies "${distro}"
    install_local_pkgbuilds "${distro}" "${desktop_interface}"
    configure_pre_install "${distro}" "${desktop_interface}"
    install_packages "${distro}"
    install_desktop_packages "${distro}" "${desktop_interface}"
    configure_nvidia_for_niri "${desktop_interface}"

    echo -e "\n${YELLOW}Stowing ${BOLD}${desktop_interface}${NC}${YELLOW} dotfile configurations...${NC}${GREEN}"

    # Load quickshell manifest replaces list for stow filtering
    local qs_replaces=()
    if [[ "${use_quickshell}" == "true" ]]; then
        mapfile -t qs_replaces < <(yq -e ".replaces[]" "${BASEDIR}/quickshell/manifest.json" 2>/dev/null)
    fi

    for dir in "${BASEDIR}/${desktop_interface}"/*/; do
        dirname=$(basename "${dir}")
        if [[ "${dirname}" == _* ]]; then
            continue
        fi
        # Skip stow packages that quickshell replaces
        if [[ "${use_quickshell}" == "true" ]]; then
            local skip="false"
            for replaced in "${qs_replaces[@]}"; do
                if [[ "${dirname}" == "${replaced}" ]]; then
                    skip="true"
                    break
                fi
            done
            [[ "${skip}" == "true" ]] && continue
        fi
        stow -v -t "${HOME}" -d "${BASEDIR}/${desktop_interface}" "${dirname}"
    done

    # Stow quickshell configs if selected
    if [[ "${use_quickshell}" == "true" ]]; then
        echo -e "\n${YELLOW}Stowing ${BOLD}quickshell${NC}${YELLOW} configurations...${NC}${GREEN}"
        [[ -d "${BASEDIR}/quickshell/quickshell" ]] && stow -v -t "${HOME}" -d "${BASEDIR}/quickshell" quickshell
        [[ -d "${BASEDIR}/quickshell/noctalia" ]] && stow -v -t "${HOME}" -d "${BASEDIR}/quickshell" noctalia
    fi

    # Generate autostart script for Wayland compositors
    if [[ "${desktop_interface}" != "gnome" ]]; then
        local compositor_config_dir
        case "${desktop_interface}" in
            "hyprland") compositor_config_dir="hypr" ;;
            *) compositor_config_dir="${desktop_interface}" ;;
        esac
        generate_autostart "${compositor_config_dir}"
    fi

    configure_desktop_interface "${distro}" "${desktop_interface}" "${scale_factor}"

    # If PaperWM was selected, install and enable it after all GNOME configuration
    if [[ "${desktop_interface}" == "gnome" && "${use_paperwm}" == "true" ]]; then
        install_paperwm
    fi

    configure_hardware
}

main "$@"
