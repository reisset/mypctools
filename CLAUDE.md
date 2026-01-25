# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

mypctools is a personal TUI (Terminal User Interface) for managing scripts and app installations across Linux systems. Built with [Gum](https://github.com/charmbracelet/gum) by Charm.

## Running the TUI

```bash
./install.sh     # First-time setup (installs gum, sets up PATH)
mypctools        # Run from anywhere after install
./launcher.sh    # Run directly from this directory
```

## Architecture

```
mypctools/
├── launcher.sh          # Main TUI entry point (gum-based menus)
├── install.sh           # Bootstrap: installs gum, creates ~/.local/bin/mypctools symlink
├── uninstall.sh         # Removes symlink and cleans up
├── lib/
│   ├── helpers.sh       # Print functions, gum wrappers, logging
│   ├── distro-detect.sh # Sets DISTRO_TYPE (arch/debian/fedora) and DISTRO_NAME
│   └── package-manager.sh # install_package() with apt/pacman/flatpak fallback chain
├── apps/                # App category menus (browsers.sh, gaming.sh, etc.)
│   └── service-manager.sh # TUI for systemctl services
└── scripts/             # Personal script bundles with install/uninstall.sh each
```

## Key Patterns

**Package installation** uses `install_package` from `lib/package-manager.sh`:
```bash
install_package "Display Name" "apt_pkg" "pacman_pkg" "flatpak_id" "fallback_fn"
```
Order: native package manager → flatpak → custom fallback function.

**Adding a new app category**: Create `apps/<category>.sh` with a `show_<category>_menu()` function, source helpers and package-manager, then add to `launcher.sh` menu.

**Adding a curl-based installer**: Add a fallback function to `lib/package-manager.sh`:
```bash
install_toolname_fallback() {
    curl -fsSL https://example.com/install.sh | bash
}
```
Then reference it in `install_package` calls: `install_package "Tool" "" "" "" "install_toolname_fallback"`

**Adding a new script bundle**: Create `scripts/<name>/` with `install.sh` and optionally `uninstall.sh`. Add menu entry in `launcher.sh:show_scripts_menu()`.

## System Setup Features

The System Setup menu (`show_system_setup_menu()` in `launcher.sh`) provides:

- **Full System Update** - Runs `apt update && apt upgrade`, `pacman -Syu`, or `dnf upgrade` based on distro
- **System Cleanup** - Removes orphan packages, clears package cache, empties user trash/thumbnails
- **Service Manager** - TUI for managing systemd services (start/stop/restart/enable/disable)
- **System Info** - Displays OS, kernel, CPU, GPU, memory, disk, packages, uptime

All sudo operations use `ensure_sudo` to pre-authenticate before running.

## Included Script Bundles

- `scripts/bash/` - Bash shell setup (Kitty, Starship, modern CLI tools). Has `--server` flag for headless installs.
- `scripts/screensavers/` - Terminal screensaver scripts
- `scripts/claude/` - Claude Code preferences and skills (copies to `~/.claude/`)
- `windows/powershell/` - Windows PowerShell configs (reference only, not runnable from Linux)

## Distro Support

Tested on Arch-based and Debian/Ubuntu-based distros. Fedora support is partial.
`DISTRO_TYPE` is exported by `lib/distro-detect.sh` and used throughout.

## Code Style

- Simple bash over clever one-liners
- Comments only where code isn't self-explanatory
- On failure, return to menu — don't exit the entire app
- Use `lib/helpers.sh` print functions for consistent output

## Gum Quick Reference

```bash
gum choose "Option 1" "Option 2"              # Single select
gum choose --no-limit "A" "B" "C"             # Multi-select
gum confirm "Proceed?" && do_thing            # Yes/no
gum spin --spinner dot --title "Working..." -- cmd < /dev/null  # Spinner (stdin must be closed!)
gum style --border normal --padding "1 2" "Title"    # Styled box
```

**Important**: Always redirect stdin from `/dev/null` when using `gum spin`. Without this, the spinner hangs indefinitely after the command completes because gum keeps waiting for stdin to close.

**Sudo commands**: Call `ensure_sudo` from `lib/helpers.sh` before running sudo commands inside `gum spin`. This prompts for the password beforehand, avoiding hangs from password prompts that can't receive input.

## Design Decisions

**curl|bash fallback installers**: The fallback functions for Ollama, OpenCode, Claude Code, and Mistral Vibe pipe directly from official vendor URLs (`curl ... | bash`). This is intentional:
- These are official installers from trusted vendors
- Simplifies code vs download-then-execute pattern
- Acceptable tradeoff for a personal tool
