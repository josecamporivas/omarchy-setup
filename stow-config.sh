#!/usr/bin/env bash

# --- Configuration ---
# An array of all Stow packages to be managed.
readonly PACKAGES=(
    bash
    hyprland
    waybar
)


# Ensures the script runs from its own directory (the dotfiles root).
cd "$(dirname "$0")" || exit
DOTFILES_ROOT=$(pwd)
echo "Operating from dotfiles root: ${DOTFILES_ROOT}"

# Verify 'stow' is installed before proceeding.
if ! command -v stow &> /dev/null; then
    echo "🔴 Error: 'stow' is not found in your PATH."
    echo "Please install GNU Stow to continue."
    exit 1
fi

# 3. Stow Execution
echo "🚀 Beginning stow operation..."
echo "Packages to stow: ${PACKAGES[*]}"

if ! stow --adopt -R -t ~ "${PACKAGES[@]}"; then
    echo "🔴 Error: stow failed. Review the conflict messages above."
    exit 1
fi

echo "✅ Stow operation complete."

# Reload Hyprland config so changes take effect immediately
if command -v hyprctl &> /dev/null; then
    hyprctl reload && echo "🔄 Hyprland config reloaded."
fi

# Restart hypridle to apply idle/lock timeout changes
if systemctl --user is-active --quiet hypridle; then
    systemctl --user restart hypridle && echo "🔄 hypridle restarted."
fi