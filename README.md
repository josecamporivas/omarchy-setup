# omarchy-setup

Dotfiles for my Omarchy / Hyprland setup, managed with GNU Stow.

## What's here

- `install-packages.sh` installs the packages wanted for the setup.
- `stow-config.sh` applies the Stow configuration to the home directory.
- `full-setup.sh` installs dependencies and runs all setup scripts.

## Usage

Make all scripts executable once after cloning:

```bash
chmod +x *.sh
```

Run the setup from the repo root:

```bash
./full-setup.sh
```

To add more apps, edit `install-packages.sh` and add package names to `PACMAN_PACKAGES` or `AUR_PACKAGES`.

If you want to run GNU Stow directly:

```bash
./stow-config.sh
```