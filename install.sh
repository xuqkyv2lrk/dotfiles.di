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

function clone_repository() {
    if [[ ! -d "${BASEDIR}" ]]; then
        echo -e "\n${BLUE}Cloning ${BOLD}${MAGENTA}dotfiles.di${NC}${BLUE} to ${BOLD}${MAGENTA}${BASEDIR}${NC}${BLUE}...${GREEN}"
        git clone -j 5 "https://gitlab.com/wd2nf8gqct/dotfiles.di.git" "${BASEDIR}"
    fi
}

# Function: detect_distro
# Description: Detects the Linux distribution of the current system.
# Returns: The ID of the detected distribution (e.g., "arch", "fedora") or "unknown" if not detected.
function detect_distro() {
    if [[ -f "/etc/os-release" ]]; then
        source "/etc/os-release"
        echo "${ID}"
    else
        echo "unknown"
    fi
}

# Function: get_package_name
# Description: Retrieves the package name for the defined distro, considering any exceptions defined in "packages.yaml".
# Parameters:
#   $1 - The default package name
#   $2 - The distribution ID
# Returns: The package name to use for installation.
function get_package_name() {
    local package
    local distro
    local package_name
    local exception

    package="${1}"
    distro="${2}"
    package_name="${package}"

    exception=$(yq -e ".exceptions.${distro}.[] | select(has(\"${package}\")) | .\"${package}\"" "${PACKAGES_YAML}")

    if [[ -n "${exception}" && "${exception}" != "null" ]]; then
        package_name="${exception}"
    fi

    echo "${package_name}"
}

# Function: install_package
# Description: Installs a specified package using the appropriate package manager for the distribution.
# Parameters:
#   $1 - The package name to install
#   $2 - The distribution ID
# Side effects: Installs the specified package on the system.
function install_package() {
    local package
    local distro
    local package_name

    package="${1}"
    distro="${2}"
    package_name=$(get_package_name "${package}" "${distro}")

    package_name="${package_name//\"/}"

    if [[ "${package_name}" == "skip" ]]; then
        return
    fi

    echo -e "\n${MAGENTA}Installing ${BOLD}${package_name}${NC}"
    case $distro in
        "arch")
            yay -S --noconfirm "${package_name}"
            ;;
        "fedora")
            sudo dnf install -y --allowerasing "${package_name}"
            ;;
        "opensuse-tumbleweed")
            sudo zypper install -y "${package_name}"
            ;;
        *)
            echo "Unsupported distribution: ${distro}"
            ;;
    esac
}

# Function: add_copr_repo
# Description: Adds COPR repositories for Fedora.
# Side effects: Adds the specified COPR repositories.
function add_copr_repo() {
    local repositories
    mapfile -t repositories < <(yq -e ".repositories.fedora.copr[]" "${PACKAGES_YAML}")
    for repo in "${repositories[@]}"; do
        echo -e "\n${YELLOW}Adding COPR repository: ${BOLD}${repo}${NC}"
        sudo dnf copr enable -y "${repo}"
    done
}

# Function: select_desktop_interface
# Description: Prompts the user to select a desktop interface.
# Parameters:
#   $1 - A reference to store the selected desktop interface.
function select_desktop_interface() {
    local __choice=$1
    echo -e "\n${BLUE}${BOLD}Do you want to install a desktop interface?${NC}"
    select choice in "Yes" "No"; do
        case $choice in
            "Yes")
                clone_repository
                echo -e "\n${BLUE}${BOLD}Please select a desktop interface:${NC}"
                mapfile -t options < <(yq -e '.desktop_packages | keys | .[]' "${PACKAGES_YAML}")
                select de in "${options[@]}"; do
                    if [[ -n "$de" ]]; then
                        eval "$__choice"="${de}"
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
}

# Function: install_dependencies
# Description: Installs necessary dependencies for the installation process.
function install_dependencies() {
    local dependencies
    local distro
    
    dependencies=("git" "yq" "stow" "rustc" "gcc-c++" "cmake" "meson")
    distro="$(detect_distro)"

    for dep in "${dependencies[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
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

    mapfile -t packages < <(yq -e ".packages[]" "${PACKAGES_YAML}")
    
    packages=("${packages[@]//\"/}")

    # TODO Create an update function for distro
    #sudo dnf -y update --setopt=protected_packages= --best --allowerasing
    
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

    mapfile -t packages < <(yq -e ".desktop_packages.${desktop_interface}[]" "${PACKAGES_YAML}")
    
    packages=("${packages[@]//\"/}")

    for package in "${packages[@]}"; do 
        install_package "${package}" "${distro}" 
    done 
}

# Function: configure_distro_specific 
# Description: Performs distribution-specific configurations.
function configure_distro_specific() {
    local distro
    local desktop_interface

    distro="${1}" 
    desktop_interface="${2}"

    case "${desktop_interface}" in 
        "gnome") ;; 
        "hyprland") ;; 
        "sway") 
            echo -e "\n${MAGENTA}Installing ${BOLD}swaysome${NC}" 
            cargo install swaysome 
                 
            if [[ "${distro}" == "fedora" ]]; then 
                add_copr_repo 
                
                # swaylock-effects
                echo -e "\n${YELLOW}Swapping package ${BOLD}swaylock${NC}${YELLOW} for ${BOLD}swaylock-effects${NC}${YELLOW}...${NC}"
                sudo dnf -y swap --setopt=protected_packages= swaylock swaylock-effects
            fi 

            if [[ "${distro}" == "opensuse-tumbleweed" ]]; then
                # Community repos to install swayfx and swaylock-effects
                # Will create own repo for these package until they are in the official repo
                sudo zypper addrepo --refresh https://download.opensuse.org/repositories/home:mantarimay:sway/standard/home:mantarimay:sway.repo
                sudo zypper addrepo --refresh https://download.opensuse.org/repositories/home:smolsheep/openSUSE_Tumbleweed/home:smolsheep.repo

                # j4-dmenu-desktop
                if ! command -v "j4-dmenu-desktop" &> /dev/null; then
                    echo -e "\n${MAGENTA}Installing ${BOLD}j4-dmenu-desktop${NC}" 
                    git clone https://github.com/enkore/j4-dmenu-desktop.git /tmp/j4
                    cd /tmp/j4
                    meson setup build
                    cd build
                    meson compile
                    sudo meson install
                fi
            fi
            ;; 
        *) 
            echo -e "\n${RED}Unsupported distribution for repository installation: ${BOLD}${distro}${NC}" 
            ;; 
    esac 
}

# Function: main 
# Description: Main function that orchestrates the installation process. 
function main() { 
    local distro=${1:-$(detect_distro)}
    local desktop_interface=${2:-} 

    if [[ -z "${distro}" ]]; then
       distro=$(detect_distro) 
    fi
    
    if [[ -z "${desktop_interface}" ]]; then
        select_desktop_interface desktop_interface 
    else
        clone_repository
    fi

    echo -e "\n${YELLOW}Preparing to install ${BOLD}${desktop_interface}${NC}${YELLOW} on ${BOLD}${distro}${NC}${YELLOW}..."

    install_dependencies "${distro}" 

    configure_distro_specific "${distro}" "${desktop_interface}"

    install_packages "${distro}"

    install_desktop_packages "${distro}" "${desktop_interface}"

    echo -e "\n${YELLOW}Stowing ${BOLD}${desktop_interface}${NC}${YELLOW} dotfile configurations...${NC}${GREEN}"

    for dir in "${BASEDIR}/${desktop_interface}/"*; do 
        stow -v -t "${HOME}" -d "${BASEDIR}/${desktop_interface}" "$(basename "${dir}")"
    done 
}

main "$@"
