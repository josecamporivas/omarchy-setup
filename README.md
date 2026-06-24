# omarchy-setup

Scripts to automate my Omarchy / Hyprland setup, managed with GNU Stow and bash scripts.

## What's here

- `uninstall-packages.sh` uninstalls the packages and webapps that are no longer wanted.
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
