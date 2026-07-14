#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")" || exit 1

readonly PACMAN_PACKAGES=(
    stow
    kate
)

readonly AUR_PACKAGES=()

install_pacman_packages() {
    if [[ ${#PACMAN_PACKAGES[@]} -eq 0 ]]; then
        return
    fi

    if ! command -v pacman >/dev/null 2>&1; then
        echo "Skipping pacman packages: pacman was not found."
        return
    fi

    echo "Installing pacman packages: ${PACMAN_PACKAGES[*]}"
    sudo pacman -S --needed --noconfirm "${PACMAN_PACKAGES[@]}"
}

install_aur_packages() {
    if [[ ${#AUR_PACKAGES[@]} -eq 0 ]]; then
        return
    fi

    local aur_helper=""
    if command -v yay >/dev/null 2>&1; then
        aur_helper="yay"
    fi

    if [[ -z "$aur_helper" ]]; then
        echo "Skipping AUR packages: neither yay nor paru was found."
        echo "Install an AUR helper first, then re-run this script."
        return 1
    fi

    echo "Installing AUR packages with ${aur_helper}: ${AUR_PACKAGES[*]}"
    "$aur_helper" -S --needed --noconfirm "${AUR_PACKAGES[@]}"
}

install_pacman_packages
install_aur_packages

echo "Package installation complete."