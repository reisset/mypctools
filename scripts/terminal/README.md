# Terminal - foot

Wayland terminal emulator configuration with curated themes.

## About foot

[foot](https://codeberg.org/dnkl/foot) is a fast, lightweight terminal emulator for Wayland. It's designed for speed and simplicity.

## Themes

- **Catppuccin Mocha** (default) — Warm, pastel colors
- **Tokyo Night** — Cool blues and purples
- **HackTheBox** — Green hacker aesthetic

## Requirements

- Wayland compositor (Hyprland, Sway, GNOME on Wayland, etc.)
- foot will not work on X11

## Installation

```bash
# Via mypctools (recommended)
mypctools
# Navigate to: Scripts → Terminal - foot

# Or manually
./install.sh
```

The installer will:
1. Install foot (if not present)
2. Install Iosevka Nerd Font
3. Let you select a theme
4. Optionally set foot as default terminal

## Shell Agnostic

This terminal config works with any shell:
- bash (see `../litebash/`)
- zsh (see `../litezsh/`)
- fish
- any other shell

## Theme Switching

Re-run the installer and select a different theme, or manually symlink:

```bash
ln -sf /path/to/scripts/terminal/configs/foot-tokyo-night.ini ~/.config/foot/foot.ini
```

## Customization

Config location: `~/.config/foot/foot.ini`

The config is symlinked to the repo, so edits to the source file in `configs/` take effect immediately.

See [foot documentation](https://codeberg.org/dnkl/foot/src/branch/master/doc/foot.ini.5.scd) for all options.

## Uninstallation

```bash
# Via mypctools
mypctools
# Navigate to: Scripts → Terminal - foot → Uninstall

# Or manually
./uninstall.sh
```

## License

MIT - see root LICENSE file.
