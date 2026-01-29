# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

mypctools is a personal TUI (Terminal User Interface) for managing scripts and app installations across Linux systems. Built with [Gum](https://github.com/charmbracelet/gum) by Charm.

See README.md for user documentation and quick start.

## Architecture

```
mypctools/
├── launcher.sh          # Main TUI entry point (gum-based menus)
├── install.sh           # Bootstrap: installs gum, creates ~/.local/bin/mypctools symlink
├── uninstall.sh         # Removes symlink and cleans up
├── lib/
│   ├── helpers.sh       # Print functions, logging, utility checks
│   ├── theme.sh         # Gum theming: themed_choose, themed_confirm, colors
│   ├── distro-detect.sh # Sets DISTRO_TYPE (arch/debian/fedora) and DISTRO_NAME
│   ├── package-manager.sh # install_package() with apt/pacman/flatpak fallback chain
│   └── tools-install.sh # Shared CLI tool install/uninstall for litebash & litezsh
├── apps/                # App category menus (browsers.sh, gaming.sh, etc.)
│   └── service-manager.sh # TUI for systemctl services
└── scripts/             # Personal script bundles with install/uninstall.sh each
    ├── shared/          # Shared assets used by multiple bundles
    │   ├── prompt/      # starship.toml (shared prompt config)
    │   └── shell/       # aliases.sh, TOOLS.md (shared by litebash & litezsh)
    ├── litebash/        # Speed-focused bash (shell config only)
    ├── litezsh/         # Speed-focused zsh (syntax highlighting, autosuggestions)
    ├── terminal/        # foot terminal config (shell-agnostic, Wayland only)
    ├── alacritty/       # alacritty terminal config (shell-agnostic, X11 + Wayland)
    ├── claude/          # Claude Code skills and statusline
    └── spicetify/       # Spotify theming
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

**Shared CLI tool installation** uses `lib/tools-install.sh`. Both litebash and litezsh source this lib to avoid duplicating GitHub-release download logic. Key functions:
- `install_all_tools` - installs zoxide, lazygit, tldr, glow, dysk, dust, yazi, starship
- `create_debian_symlinks` - creates bat/fd symlinks on Debian
- `uninstall_local_tools` - removes all tools from `~/.local/bin`
- `install_starship_config` / `uninstall_starship_config` - manages the shared starship.toml symlink

The canonical `starship.toml` lives in `scripts/shared/prompt/` and both bundles symlink to it.

**Shared shell assets** live in `scripts/shared/shell/`:
- `aliases.sh` - 26 aliases shared by litebash and litezsh
- `TOOLS.md` - quick reference for all CLI tools (includes zsh features section)

## System Setup Features

The System Setup menu (`show_system_setup_menu()` in `launcher.sh`) provides:

- **Full System Update** - Runs `apt update && apt upgrade`, `pacman -Syu`, or `dnf upgrade` based on distro
- **System Cleanup** - Removes orphan packages, clears package cache, empties user trash/thumbnails
- **Service Manager** - TUI for managing systemd services (start/stop/restart/enable/disable)
- **System Info** - Displays OS, kernel, CPU, GPU, memory, disk, packages, uptime

All sudo operations use `ensure_sudo` to pre-authenticate before running.

## Included Script Bundles

- `scripts/litebash/` - Speed-focused bash environment with modern CLI tools (eza, bat, ripgrep, fd, zoxide, lazygit, yazi, starship). Shell config only.
- `scripts/litezsh/` - Zsh counterpart to litebash with native syntax highlighting, autosuggestions, and arrow-key completion. Auto-sets zsh as default shell.
- `scripts/terminal/` - foot terminal config (Wayland only). Shell-agnostic — works with bash, zsh, or any shell. Themes: Catppuccin Mocha, Tokyo Night, HackTheBox.
- `scripts/alacritty/` - alacritty terminal config (X11 + Wayland). Shell-agnostic. Same themes as foot.
- `scripts/claude/` - Claude Code skills (pdf, docx, xlsx, pptx, bloat-remover) and statusline
- `scripts/spicetify/` - Spicetify + StarryNight theme for native Spotify installs

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
