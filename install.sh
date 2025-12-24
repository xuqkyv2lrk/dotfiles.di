#!/usr/bin/env bash

set -eu

BOLD="\033[1m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
MAGENTA="\033[35m"
NC="\033[0m"

BASEDIR="${HOME}/.dotfiles.di"
PACKAGES_YAML="${BASEDIR}/packages.yaml"

# Global variable to track PaperWM selection
use_paperwm="false"

# Function: clone_repository
# Description: Clones the dotfiles repository if it doesn't exist.
function clone_repository() {
    if [[ ! -d "${BASEDIR}" ]]; then
        echo -e "\n${BLUE}Cloning ${BOLD}${MAGENTA}dotfiles.di${NC}${BLUE} to ${BOLD}${MAGENTA}${BASEDIR}${NC}${BLUE}...${GREEN}"
        git clone -j 5 "https://gitlab.com/wd2nf8gqct/dotfiles.di.git" "${BASEDIR}"
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
# Description: On Ubuntu, prompts the user to apply a custom GNOME configuration or leave the current setup unchanged. On other distros, prompts for desktop interface selection.
function select_desktop_interface() {
    local __choice=$1
    local distro
    distro=$(detect_distro)
    if [[ "$distro" == "ubuntu" ]]; then
        # Check if the current desktop session is GNOME
        if [[ "$XDG_CURRENT_DESKTOP" != *"GNOME"* && "$DESKTOP_SESSION" != "gnome" ]]; then
            echo -e "\n${RED}Unsupported desktop environment detected.\nThis script supports only Ubuntu with GNOME desktop. Exiting.${NC}\n"
            exit 1
        fi
        echo -e "\n${BLUE}${BOLD}You are running Ubuntu with GNOME.${NC}"
        echo -e "${BLUE}How would you like to handle your GNOME desktop configuration?${NC}"
        select choice in "Apply custom GNOME configuration" "Apply custom GNOME configuration with PaperWM" "Leave GNOME as it is"; do
            case $choice in
                "Apply custom GNOME configuration")
                    eval "$__choice"="gnome"
                    use_paperwm="false"
                    return
                    ;;
                "Apply custom GNOME configuration with PaperWM")
                    eval "$__choice"="gnome"
                    use_paperwm="true"
                    return
                    ;;
                "Leave GNOME as it is")
                    printf "\nNo changes will be made to your GNOME desktop.\n"
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
                    mapfile -t options < <(yq -e '.desktop_packages | keys | .[]' "${PACKAGES_YAML}" 2>/dev/null | tr -d '"')
                    select de in "${options[@]}"; do
                        if [[ -n "$de" ]]; then
                            eval "$__choice"="$de"
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
    for package in "${packages[@]}"; do
        install_package "${package}" "${distro}"
    done
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
            ;;
        *)
            echo -e "\n${RED}Unsupported desktop interface: ${BOLD}${desktop_interface}${NC}"
            ;;
    esac
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

# Function: configure_desktop_interface
# Description: Performs desktop interface configurations post installation.
function configure_desktop_interface() {
    local distro
    local desktop_interface
    local gpg_config_file
    local pinentry_line
    distro="${1}"
    desktop_interface="${2}"
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

            echo -e "\n${BLUE}${BOLD}Enabling fractional scaling...${NC}"
            gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer']"
            echo -e "${GREEN}Enabled fractional scaling${NC}"

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
            install_colloid_catppuccin
            systemctl --user enable --now idle.service
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
    install_package "nvidia-dkms" "${distro}"
    local mkinitcpio_conf="/etc/mkinitcpio.conf"
    local required_modules="nvidia nvidia_modeset nvidia_uvm nvidia_drm"
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
    if [[ -d /boot/loader/entries ]]; then
        local updated_any=0
        for entry in /boot/loader/entries/*.conf; do
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
#   $2 - (Optional) The desktop interface (e.g., "gnome", "hyprland"). If not provided, user is prompted.
#   $3 - (Optional) PaperWM option ("true" or "false"). If not provided, defaults to "false".
function main() {
    local distro=${1:-$(detect_distro)}
    local desktop_interface=${2:-}
    local paperwm_option=${3:-"false"}

    # Set the global variable based on the parameter
    use_paperwm="${paperwm_option}"

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
        select_desktop_interface desktop_interface
    else
        clone_repository
        # If desktop_interface is provided but paperwm_option wasn't set and it's gnome, keep the current use_paperwm value
        if [[ "${desktop_interface}" == "gnome" && "${paperwm_option}" == "false" && -z "${3}" ]]; then
            use_paperwm="false"
        fi
    fi

    echo -e "\n${YELLOW}Preparing to install ${BOLD}${desktop_interface}${NC}${YELLOW} on ${BOLD}${distro}${NC}${YELLOW}..."
    install_dependencies "${distro}"
    configure_pre_install "${distro}" "${desktop_interface}"
    install_packages "${distro}"
    install_desktop_packages "${distro}" "${desktop_interface}"
    configure_nvidia_for_niri "${desktop_interface}"

    echo -e "\n${YELLOW}Stowing ${BOLD}${desktop_interface}${NC}${YELLOW} dotfile configurations...${NC}${GREEN}"
    for dir in "${BASEDIR}/${desktop_interface}"/*/; do
        dirname=$(basename "${dir}")
        if [[ "${dirname}" == _* ]]; then
            continue
        fi
        stow -v -t "${HOME}" -d "${BASEDIR}/${desktop_interface}" "${dirname}"
    done

    configure_desktop_interface "${distro}" "${desktop_interface}"

    # If PaperWM was selected, install and enable it after all GNOME configuration
    if [[ "${desktop_interface}" == "gnome" && "${use_paperwm}" == "true" ]]; then
        install_paperwm
    fi

    configure_hardware
}

main "$@"
