# Changelog

All notable changes to mypctools and its bundled scripts.

---

## mypctools

### [0.4.5] - 2026-01-28

#### Added
- `--help` and `--version` CLI flags
- Compact system info line (distro, kernel, shell) on main menu screen

#### Removed
- Settings menu (only contained an About page — info moved to `--help`)

---

### [0.4.4] - 2026-01-28

#### Removed
- Bash Setup script bundle (`scripts/bash/`) — deprecated, superseded by LiteBash
- Screensavers script bundle (`scripts/screensavers/`) — unused

---

### [0.4.3] - 2026-01-28

#### Fixed
- litezsh: FZF keybindings now work on Debian (added `/usr/share/doc/fzf/examples/` fallback path)
- screensavers: PATH instructions now detect user's shell and suggest correct rc file (~/.zshrc or ~/.bashrc)
- spicetify: Added `/usr/lib/spotify` path for Debian official repo installs

---

### [0.4.2] - 2026-01-28

#### Added
- LiteZsh script bundle (zsh shell config with native syntax highlighting and autosuggestions)
- Terminal - foot as standalone script (moved from litebash)

#### Changed
- Restructured scripts/litebash: terminal config moved to scripts/terminal
- TUI menu now shows LiteBash, LiteZsh, and Terminal - foot as separate items

---

### [0.4.1] - 2026-01-28

#### Fixed
- `command_exists()` now rejects empty strings (was returning true)
- Update check race condition: increased wait from 0.1s to 0.5s

#### Changed
- Claude Setup no longer installs CLAUDE.md (users manage their own preferences)

---

## scripts/claude

### [1.6.0] - 2026-01-28

#### Added
- jq dependency check before installation (fails clearly if missing)
- statusline.sh fallback message if jq unavailable at runtime

#### Removed
- Bundled CLAUDE.md (redundant - users should maintain their own ~/.claude/CLAUDE.md)

#### Changed
- statusline.sh bumped to v1.1

---

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

## scripts/litebash

### [1.4.0] - 2026-01-27

#### Terminal (v1.4.0)
- Refactored to symlink configs instead of generating (edits now take effect immediately)
- Removed Shift+Space text binding
- Moved complete theme configs to `terminal/configs/`

### [1.3.1] - 2026-01-27

#### Shell (v1.2.1)
- Fixed starship config: symlink instead of copy (edits now take effect immediately)
- Fixed starship format string syntax ($os $username)
- Fixed username style variable (style instead of style_user)

### [1.3.0] - 2026-01-27

#### Shell (v1.2.0)
- New two-line prompt with box-drawing connectors
- Added OS icon (auto-detects distro via nerd fonts)
- Added username display
- Added "in" / "on" / "took" connectors for readability
- cmd_duration now shows "took Xs" for slow commands
- git_status still disabled for speed

### [1.2.1] - 2026-01-27

#### Terminal (v1.3.1)
- Fixed font size (14 → 17) - was too small on COSMIC
- Changed cursor style from beam to block
- Added selection colors to HackTheBox theme (green highlight)

### [1.2.0] - 2026-01-27

#### Terminal (v1.3.0)
- Fixed COSMIC default terminal - xdg-terminals.list doesn't work (COSMIC hardcodes cosmic-term)
- COSMIC now creates custom keybinding: Super+Enter launches foot
- Keybinding stored in `~/.config/cosmic/com.system76.CosmicSettings.Shortcuts/v1/custom`

### [1.1.0] - 2026-01-27

#### Shell (v1.1.0)
- Added `dust` disk usage analyzer (bootandy/dust)
- Reset starship.toml to defaults (only git_status disabled for performance)
- Removed `df='dysk'` alias (dysk/dust are standalone commands now)
- Created TOOLS.md quick reference
- Fixed TOOLS.md path reference in installer

#### Terminal (v1.2.0)
- Improved default terminal detection for multiple desktop environments
- GNOME (Ubuntu): uses `update-alternatives` for x-terminal-emulator
- COSMIC (Pop!_OS 24.04+): uses `xdg-terminals.list` (xdg-terminal-exec spec) - **Note: doesn't work, fixed in v1.3.0**
- Hyprland/Sway: uses `xdg-terminals.list`
- Case-insensitive desktop detection

#### Documentation
- Updated README for mypctools TUI integration
- Fixed install/uninstall instructions

### [1.0.0] - 2026-01-25
- Initial release
- Shell: eza, bat, ripgrep, fd, fzf, zoxide, btop, lazygit, micro, yazi, starship, tealdeer, glow, dysk, gh
- Terminal: foot with Catppuccin Mocha, Tokyo Night, HackTheBox themes
- Speed-optimized starship prompt (git_status disabled)

---

## scripts/litezsh

### [1.0.0] - 2026-01-28
- Initial release
- Zsh counterpart to LiteBash (same tools, same prompt)
- Zsh-native syntax highlighting (zsh-syntax-highlighting plugin)
- Zsh-native autosuggestions (zsh-autosuggestions plugin)
- Arrow-key completion with menu navigation
- History substring search (type partial command, press up-arrow)
- Auto-sets zsh as default shell
- Same CLI tools: eza, bat, ripgrep, fd, fzf, zoxide, btop, lazygit, micro, yazi, starship, tealdeer, glow, dysk, dust, gh

---

## scripts/terminal

### [1.0.0] - 2026-01-28
- Standalone foot terminal config (moved from litebash/terminal)
- Shell-agnostic: works with bash, zsh, fish, or any shell
- Themes: Catppuccin Mocha (default), Tokyo Night, HackTheBox
- Iosevka Nerd Font installation
- Desktop-aware default terminal setup (GNOME, COSMIC, Hyprland/Sway)

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
