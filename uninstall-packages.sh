#!/usr/bin/env bash

set -uo pipefail

cd "$(dirname "$0")" || exit 1

readonly PACMAN_PACKAGES=(
    1password-beta
    1password-cli
    xournalpp
    typora
    spotify
    signal-desktop
    chromium
)

readonly WEBAPPS=(
    "WhatsApp"
    "Basecamp"
    "Figma"
    "Fizzy"
    "Google Contacts"
    "Google Messages"
    "Google Photos"
    "HEY"
    "Zoom"
)

remove_pacman_packages() {
    if [[ ${#PACMAN_PACKAGES[@]} -eq 0 ]]; then
        return
    fi

    command -v pacman >/dev/null 2>&1 || {
        echo "Skipping pacman removal: pacman not found."
        return
    }

    local installed=()

    for pkg in "${PACMAN_PACKAGES[@]}"; do
        pacman -Q "$pkg" >/dev/null 2>&1 && installed+=("$pkg") || true
    done

    if [[ ${#installed[@]} -eq 0 ]]; then
        echo "No matching pacman packages installed."
        return
    fi

    echo "Removing pacman packages: ${installed[*]}"
    sudo pacman -Rns --noconfirm "${installed[@]}" || {
        echo "Pacman removal completed with warnings."
    }

    # Clean up leftover .desktop files in ~/.local/share/applications
    local desktop_dir="$HOME/.local/share/applications"
    for pkg in "${installed[@]}"; do
        rm -f "$desktop_dir/$pkg.desktop" || true
    done
}

remove_webapps() {
    local desktop_dir="$HOME/.local/share/applications"
    local icon_dir="$desktop_dir/icons"

    if [[ ${#WEBAPPS[@]} -eq 0 ]]; then
        return
    fi

    echo "Removing webapps..."

    for app in "${WEBAPPS[@]}"; do
        rm -f "$desktop_dir/$app.desktop" || true
        rm -f "$icon_dir/$app.png" || true
        echo "Removed webapp: $app"
    done
}

refresh_ui() {
    command -v omarchy-restart-walker >/dev/null 2>&1 || return

    echo "Refreshing Omarchy UI..."

    # Never let systemd failures break the script
    systemctl --user reset-failed elephant.service >/dev/null 2>&1 || true
    systemctl --user reset-failed app-walker@autostart.service >/dev/null 2>&1 || true

    omarchy-restart-walker >/dev/null 2>&1 || true
}

remove_pacman_packages
remove_webapps
refresh_ui

echo "Uninstallation complete."