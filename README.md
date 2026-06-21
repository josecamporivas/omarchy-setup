# omarchy-setup

Dotfiles for my Omarchy / Hyprland setup, managed with GNU Stow.

## What's here

- `stow-config.sh` applies the Stow configuration to the home directory.
- `full-setup.sh` installs dependencies and runs all setup scripts.

## Usage

Make both scripts executable once after cloning:

```bash
chmod +x full-setup.sh stow-config.sh
```

Run the setup from the repo root:

```bash
./full-setup.sh
```

If you want to run GNU Stow directly:

```bash
./stow-config.sh
```

