# Changelog

All notable changes to mypctools and its bundled scripts.

---

## mypctools

### [0.4.0] - 2026-01-25

#### Added
- ASCII art logo in main menu
- Silent version check with "Pull Updates" option when available
- Full System Update command (apt/pacman/dnf upgrade)
- System Cleanup command (remove orphans, clear caches, empty trash)
- Service Manager TUI for systemctl services

#### Removed
- "Check for Updates" submenu (replaced by automatic check)
- "Coming Soon..." placeholder in System Setup

### [0.3.1] - Unreleased

#### Added
- Fedora/dnf support in `install_package()`
- Design decisions section in CLAUDE.md

#### Removed
- Caligula ISO burner from CLI Utilities menu
- Stale tool references from bash/uninstall.sh

#### Fixed
- Fedora support was broken: `get_package_manager()` returned "dnf" but `install_package()` didn't handle it

### [0.3.0]

#### Removed
- Unused gum wrapper functions from lib/helpers.sh
- Empty `configs/` directory

#### Added
- Discord to Media apps menu
- `ensure_sudo()` helper function

#### Fixed
- gum spin hanging after package installations
- sudo password prompts hanging inside gum spin
- .NET SDK installation case mismatch
- .NET SDK detection

---

## scripts/bash (MyBash)

### [2.8.8] - 2026-01-22
- Fixed lazygit GitHub release pattern (releases use `x86_64` not `amd64`)

### [2.8.6] - 2026-01-22
- Added COSMIC Desktop Support (Pop!_OS 24.04)

### [2.8.0] - 2026-01-16
- Added GitHub CLI (gh)
- Fixed KDE Plasma Ctrl+Alt+T shortcut

### [2.7.2] - 2026-01-15
- Added KDE Plasma Support for Kitty default terminal

### [2.7.0] - 2026-01-11
- Added Starship time display
- Added Docker context display in prompt

### [2.6.0] - 2026-01-10
- Added Kitty Kitten integration (icat, kdiff, hints)

### [2.5.0] - 2026-01-10
- Added Kitty framed aesthetic (tab bar, borders)
- Removed Zellij (redundant with Kitty features)
- Removed unused CLI tools (bandwhich, hyperfine, tokei)

### [2.3.0] - 2026-01-02
- Added unified `mybash` CLI
- Added Micro editor as default
- FZF auto-enabled on install

### [2.2.0] - 2025-12-22
- Added uninstall script with manifest tracking

### [2.0.0] - 2024-12-20
- Major release: Modern CLI toolset (zoxide, eza, bat, fzf, fd, ripgrep, delta, lazygit, btop)
- Kitty terminal with Tokyo Night theme
- Starship prompt
- Server mode (`--server` flag)
- ARM64 support

---

## scripts/screensavers

### [v1.2.1] - 2026-01-15
- Fixed daemon startup validation

### [v1.2.0] - 2026-01-15
- Added Ghostty terminal support
- Added config file support (`~/.config/myscreensavers/config`)
- Added screen lock integration
- Added uninstall script

### [v1.1.0] - 2026-01-13
- Multi-distro support (Arch, Fedora, Debian)
- Multi-DE support (GNOME, Hyprland, Sway, X11, KDE)
- Added foot terminal support

### [v1.0.0] - 2026-01-07
- Battery saver mode
- Instant wake-up on user activity

### [v0.8.0] - 2026-01-05
- Major rewrite from Python/YAML to Bash
- Seamless effect transitions
