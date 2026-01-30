# Changelog

All notable changes to mypctools and its bundled scripts.

> **Maintenance Note**: When fixing bugs, always fix THE SCRIPT, not the user's
> system manually. Scripts must work end-to-end on first run. If a script fails,
> the fix goes in the script—never patch the user's config files directly as a
> workaround. The goal: run once, log out, done.

---

## mypctools

### [0.5.8] - 2026-01-30

#### Added
- Docker Compose to Dev Tools menu (separate from Docker engine)

---

### [0.5.7] - 2026-01-30

#### Fixed
- Docker indicator in starship prompt now works with modern `compose.yaml` files
  - Replaced `docker_context` module with `custom.docker` (starship bug ignores `compose.yaml`)
  - Nerd Font glyph () required UTF-8 byte insertion via bash printf (same fix as OS icons)

---

### [0.5.6] - 2026-01-30

#### Fixed
- **Removed `set -e` from 11 scripts** — prevents silent failures, ensures all cleanup steps complete:
  - `install.sh`, `uninstall.sh` (root)
  - `scripts/litebash/uninstall.sh`, `scripts/litezsh/uninstall.sh`
  - `scripts/terminal/install.sh`, `scripts/terminal/uninstall.sh`
  - `scripts/alacritty/install.sh`, `scripts/alacritty/uninstall.sh`
  - `scripts/claude/install.sh`, `scripts/claude/uninstall.sh`
  - `scripts/spicetify/install.sh`
- `scripts/litezsh/uninstall.sh`: Shell detection now uses `getent passwd` (was `$SHELL` which is empty in TUI)
- `scripts/litezsh/uninstall.sh`: Added `chsh` → `usermod` fallback (matches install.sh pattern)
- Terminal font size standardized to 15 across all themes (foot + alacritty configs)

---

### [0.5.5] - 2026-01-30

#### Fixed
- `install.sh`: Now automatically adds `~/.local/bin` to PATH in `.bashrc`/`.zshrc` (was only warning)
- `lib/tools-install.sh`: `install_starship_config()` now uses `|| true` to prevent `set -e` script death

---

### [0.5.4] - 2026-01-29

#### Fixed
- `launcher.sh`: Version synced to 0.5.4 (was showing 0.5.1/0.5.2)
- `scripts/alacritty/uninstall.sh`: Fixed `Alacritty.desktop` capitalization (missed in bb3f95d)

---

### [0.5.3] - 2026-01-29

#### Added
- `safe_symlink()` helper in `lib/tools-install.sh` — validates source exists, skips if already configured, backs up existing files
- Same helper added to `scripts/terminal/install.sh` and `scripts/alacritty/install.sh`

#### Fixed
- `lib/tools-install.sh`: `SHARED_STARSHIP_TOML` now resolved to absolute path (was relative `../`)
- `lib/tools-install.sh`: `install_starship_config()` now backs up existing user configs instead of silently overwriting
- `install.sh`: Bootstrap symlink now checks if already pointing to our launcher before replacing
- `scripts/litezsh/install.sh`: Now verifies ALL 5 symlinks (was only checking first one)
- `scripts/terminal/uninstall.sh`: Now detects broken symlinks (`[ -L ]` added to `[ -f ]` check)
- `scripts/alacritty/install.sh`: Config symlink now uses safe_symlink with backup

---

### [0.5.2] - 2026-01-29

#### Fixed
- `lib/package-manager.sh`: `install_lazygit_fallback()` now uses `mktemp -d` with subshell (was using fixed `/tmp` paths)
- `lib/package-manager.sh`: `install_lazydocker_fallback()` same fix
- `scripts/alacritty/install.sh`: Font install wrapped in subshell to avoid CWD in deleted directory
- `scripts/terminal/install.sh`: Same subshell fix for font install

---

### [0.5.1] - 2026-01-29

#### Added
- Lazygit to Dev Tools menu (standalone install option)
- `install_lazygit_fallback()` in `lib/package-manager.sh` (GitHub binary release)
- Alacritty terminal script bundle (`scripts/alacritty/`)
- Alacritty themes: Catppuccin Mocha, Tokyo Night, HackTheBox (matching foot)

---

### [0.5.0] - 2026-01-29

#### Removed
- CLI Utilities menu from Install Apps (redundant — all tools already installed by LiteBash/LiteZsh, gum installed by bootstrap)
- `apps/cli-utils.sh`

---

### [0.4.9] - 2026-01-29

#### Changed
- Consolidated shared shell aliases into `scripts/shared/shell/aliases.sh`
- Consolidated TOOLS.md into `scripts/shared/shell/TOOLS.md` (includes zsh features for all users)
- LiteBash and LiteZsh now source the same shared files

#### Removed
- `scripts/litebash/aliases.sh` — moved to shared
- `scripts/litebash/TOOLS.md` — moved to shared
- `scripts/litezsh/aliases.zsh` — moved to shared
- `scripts/litezsh/TOOLS.md` — moved to shared

---

### [0.4.8] - 2026-01-28

#### Removed
- Unused `show_title()` function from `lib/theme.sh` (defined but never called)

#### Audited (all clean)
- 87 functions across all `.sh` files — all called (except the removed `show_title`)
- All `source` statements point to existing files
- All `launcher.sh` menu entries map to real functions/scripts
- All config files in `scripts/shared/` and `scripts/terminal/configs/` are referenced
- All `.md` documentation is accurate with no references to deleted features
- No commented-out code blocks, no TODO/FIXME/HACK markers, no debug prints
- No orphaned files — every file is sourced, executed, copied, or symlinked
- No unused variables — all exports consumed by child scripts/sourced libs

---

### [0.4.7] - 2026-01-28

#### Fixed
- `lib/tools-install.sh`: starship install now checks exit code instead of silently succeeding on failure
- `lib/tools-install.sh`: GitHub tool installers no longer leak CWD into deleted tmpdir (wrapped in subshells)
- `lib/tools-install.sh`: Debian symlink check uses `-e` instead of `-f` (handles broken symlinks)
- `lib/package-manager.sh`: lazydocker fallback detects CPU architecture instead of hardcoding x86_64
- `launcher.sh`: update check guards empty `$behind` variable before numeric comparison

#### Added
- `lib/tools-install.sh`: `install_starship_config()` creates `~/.config` if missing
- `apps/service-manager.sh`: `crond` service for Fedora (alongside `cron` for Debian/Arch)

#### Removed
- Dead `scripts/litebash/prompt/starship.toml` and `scripts/litezsh/prompt/starship.toml` (superseded by shared config)

---

### [0.4.6] - 2026-01-28

#### Added
- `lib/tools-install.sh` — shared CLI tool install/uninstall lib for litebash & litezsh
- `scripts/shared/prompt/starship.toml` — canonical starship config used by both bundles
- Confirmation prompt before orphan package removal on Arch (System Cleanup)
- Unknown distro warning in `lib/distro-detect.sh`

#### Fixed
- Service Manager: systemctl actions now check return codes and show errors on failure
- `install.sh`: symlink creation handles pre-existing regular files (not just symlinks)
- `lib/package-manager.sh`: temp files use `mktemp` instead of predictable `/tmp` paths
- `lib/package-manager.sh`: lazydocker version parsing uses `jq` when available (grep fallback)

---

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

### [0.3.1]

#### Added
- Fedora/dnf support in `install_package()`
- Design decisions section in CLAUDE.md

#### Removed
- Caligula ISO burner from CLI Utilities menu

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

### [1.9.0] - 2026-01-30

#### Fixed
- **CRITICAL**: Removed `set -e` — was causing silent script death on any error
- Script now completes ALL critical steps (config copy, .bashrc, shell change) even if optional steps fail
- `set_default_shell()`: Now checks `/etc/passwd` directly (not `$SHELL`)
- `set_default_shell()`: Refreshes sudo before shell change
- `set_default_shell()`: Falls back to `usermod -s` if `chsh` fails
- Config file copy failures now tracked and reported (was silent crash)
- Package database update failures no longer abort install

---

### [1.8.0] - 2026-01-29

#### Fixed
- `install.sh`: Starship config now uses safe_symlink with backup (was silently overwriting)

---

### [1.7.0] - 2026-01-29

#### Fixed
- Auto-ls on `cd` now matches updated `ls` alias (`eza -lh --group-directories-first --icons=auto`)
- Auto-ls now triggers on zoxide `z` and `zi` commands (overrides `__zoxide_cd` after init)

---

### [1.6.0] - 2026-01-29

#### Changed
- Aliases now sourced from shared `scripts/shared/shell/aliases.sh`
- TOOLS.md now copied from shared `scripts/shared/shell/TOOLS.md`
- `tools` alias moved from aliases.sh to litebash.sh

---

### [1.5.0] - 2026-01-28

#### Changed
- Tool installation refactored to use shared `lib/tools-install.sh`
- Starship config now symlinks to `scripts/shared/prompt/starship.toml`
- Uninstaller uses shared lib (now correctly removes `dust` on uninstall)

---

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
- COSMIC (Pop!_OS 24.04+): uses `xdg-terminals.list` (xdg-terminal-exec spec)
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

### [1.6.0] - 2026-01-30

#### Fixed
- **CRITICAL**: Removed `set -e` — was causing silent script death on any error
- Script now completes ALL critical steps (symlinks, .zshrc, shell change) even if optional steps fail
- `set_default_shell()`: Now checks `/etc/passwd` directly (not `$SHELL` which was empty in TUI)
- `set_default_shell()`: Refreshes sudo before shell change (credentials may expire during long install)
- `set_default_shell()`: Falls back to `usermod -s` if `chsh` fails
- `install_zsh()`: Verifies zsh actually installed after package manager runs
- `install_plugins()`: Git clone failures now warn instead of crashing script
- Package database update failures no longer abort install

---

### [1.5.0] - 2026-01-30

#### Fixed
- `install.sh`: Added starship config verification with manual fallback

---

### [1.4.0] - 2026-01-29

#### Fixed
- `install.sh`: All 5 config symlinks now validated (was only checking first)
- `install.sh`: Uses safe_symlink with source validation and backup

---

### [1.3.0] - 2026-01-29

#### Fixed
- Auto-ls on `cd` now matches updated `ls` alias (`eza -lh --group-directories-first --icons=auto`)
- Auto-ls now triggers on zoxide `z` and `zi` commands (overrides `__zoxide_cd` after init)

---

### [1.2.0] - 2026-01-29

#### Changed
- Aliases now sourced from shared `scripts/shared/shell/aliases.sh`
- TOOLS.md now symlinked from shared `scripts/shared/shell/TOOLS.md`
- `tools` alias moved from aliases.zsh to litezsh.zsh
- Alias file now named `aliases.sh` (was `aliases.zsh`, compatible with both shells)

---

### [1.1.0] - 2026-01-28

#### Changed
- Tool installation refactored to use shared `lib/tools-install.sh`
- Starship config now symlinks to `scripts/shared/prompt/starship.toml`
- Uninstaller uses shared lib

#### Removed
- Unnecessary `jq` dependency (was copy-pasted from claude/install.sh, never used)

---

### [1.0.1] - 2026-01-28

#### Fixed
- Starship prompt OS icon missing — symbols were plain spaces instead of Nerd Font glyphs

---

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

### [1.1.0] - 2026-01-29

#### Fixed
- `install.sh`: Config symlink now uses safe_symlink with source validation and backup
- `uninstall.sh`: Now detects and removes broken symlinks (added `[ -L ]` check)

---

### [1.0.0] - 2026-01-28
- Standalone foot terminal config (moved from litebash/terminal)
- Shell-agnostic: works with bash, zsh, fish, or any shell
- Themes: Catppuccin Mocha (default), Tokyo Night, HackTheBox
- Iosevka Nerd Font installation
- Desktop-aware default terminal setup (GNOME, COSMIC, Hyprland/Sway)

---

## scripts/alacritty

### [1.2.0] - 2026-01-29

#### Fixed
- `uninstall.sh`: Fixed `Alacritty.desktop` capitalization (missed in bb3f95d)

---

### [1.1.0] - 2026-01-29

#### Fixed
- `install.sh`: Config symlink now uses safe_symlink with source validation and backup

---

### [1.0.0] - 2026-01-29
- Initial release
- Shell-agnostic: works with bash, zsh, fish, or any shell
- Works on both X11 and Wayland (unlike foot)
- Themes: Catppuccin Mocha (default), Tokyo Night, HackTheBox
- Iosevka Nerd Font installation (same as foot)
- Desktop-aware default terminal setup (GNOME, COSMIC, Hyprland/Sway/X11)

