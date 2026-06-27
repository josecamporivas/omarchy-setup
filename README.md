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

## Additional packages (NOT installed by default)

This setup does not install the following packages by default, but they are available in the `additional-packages` folder. You can install them by running the individual scripts, for example:

```bash
./additional-packages/install-latex.sh
```

Here are the additional packages available:
- LaTeX (`install-latex.sh`)
- Maven (`install-maven.sh`)
- Bun (`install-bun.sh`)
