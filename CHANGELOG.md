# Changelog

All notable changes to mypctools and its bundled scripts.

> **Maintenance Note**: When fixing bugs, always fix THE SCRIPT, not the user's
> system manually. Scripts must work end-to-end on first run. If a script fails,
> the fix goes in the script—never patch the user's config files directly as a
> workaround. The goal: run once, log out, done.

---

## mypctools

### [0.9.0] - 2026-02-04

#### Added
- **`lib/print.sh`** — shared print functions (zero gum dependency), sourced by 12+ scripts instead of copy-pasting
- **`lib/symlink.sh`** — single canonical `safe_symlink` implementation with path resolution, backup, and idempotency
- **`lib/shell-setup.sh`** — parametric `set_default_shell <path>` shared by litebash and litezsh
- **`init_sudo()`** in `lib/print.sh` — sudo prompt + background keepalive for long-running installers
- **`themed_pause()`** in `lib/theme.sh` — styled replacement for raw `read -rp "Press Enter..."`
- **`show_install_summary()`** in `lib/theme.sh` — displays succeeded/failed counts after batch installs
- **Breadcrumb navigation** — all submenus now show parent context (e.g., "Install Apps > AI Tools")
- **Batch progress indicators** — app menus now show `[1/5] Installing...` during multi-package installs
- **Colored service indicators** — service-manager status symbols are now green (active), yellow (enabled/stopped), gray (stopped)
- **`gum choose` for theme selection** — terminal installers use themed menu when gum is available (with `read -rp` fallback)
- `lib/distro-detect.sh` now exports `PKG_MGR`, `PKG_INSTALL`, `PKG_UPDATE` alongside `DISTRO_TYPE`/`DISTRO_NAME`

#### Changed
- **Full System Update now shows live output** — replaced hidden spinner with streamed package manager output (mirrors, progress, errors visible in real time) with error tracking and styled dividers
- **Major code consolidation** — 22 files changed, net -255 lines removed
- Print functions standardized to `print_status`/`print_success`/`print_warning`/`print_error` across entire project
- `install.sh` / `uninstall.sh` renamed from `print_step`/`print_ok`/`print_warn`/`print_fail`
- All app menus (`apps/*.sh`) now show install summary instead of generic "Done!"
- All `read -rp "Press Enter..."` in `launcher.sh` replaced with `themed_pause`

#### Fixed
- **Unquoted `$orphans` variable** in `launcher.sh` — was interpolated inside single quotes in `bash -c`, variable never expanded; now passed as positional arg
- **Trash/thumbnail deletion without confirmation** — `launcher.sh` System Cleanup now asks before clearing `~/.cache/thumbnails` and `~/.local/share/Trash`
- **`readlink -f` empty path** in `lib/terminal-install.sh` — added explicit empty-string check for better error message
- **`which` replaced with `command -v`** in litebash/litezsh installers — more portable, with empty-result guard

#### Removed
- Duplicate `detect_distro()` from `lib/terminal-install.sh`, `scripts/litebash/install.sh`, `scripts/litezsh/install.sh` (now source `lib/distro-detect.sh`)
- Duplicate `safe_symlink()` from `lib/tools-install.sh` and `lib/terminal-install.sh` (now source `lib/symlink.sh`)
- Duplicate `init_sudo()` from `lib/terminal-install.sh` (now in `lib/print.sh`)
- Duplicate `set_default_shell()` from litebash and litezsh installers (now in `lib/shell-setup.sh`)
- Inline color definitions + print functions from 12 files (now source `lib/print.sh`)

---

### [0.8.0] - 2026-02-04

#### Added
- **Fastfetch script bundle** (`scripts/fastfetch/`) — custom config with boxed layout, nerd font icons, color-coded sections (system/desktop/hardware), small distro logo, and color palette strip
- **`lib/terminal-install.sh`** — shared lib for terminal emulator installers (`safe_symlink`, `detect_distro`, `select_theme`, `install_font`, `set_default_terminal`)
- `show_script_submenu()` in `launcher.sh` — generic handler for all script bundle Install/Uninstall/Back menus

#### Changed
- **Script menu consolidated**: 9 identical 30-line menu blocks replaced with single-line calls to `show_script_submenu()` (launcher.sh: 669 → 419 lines)
- **Terminal installers refactored**: all 4 bundles (foot, alacritty, ghostty, kitty) now source `lib/terminal-install.sh` instead of duplicating shared functions (~1130 → ~490 total lines)
- `README.md` updated with Fastfetch and Screensaver bundle entries

#### Removed
- Unused `show_keyhints()` from `lib/theme.sh`

---

### [0.7.0] - 2026-02-03

#### Added
- **Screensaver script bundle** (`scripts/screensaver/`) — Omarchy-style terminal screensaver using tte (Terminal Text Effects)
- Launches fullscreen Alacritty on all Hyprland monitors with random tte effects over ASCII art
- Two ASCII art files (LINUX GANG block letters, Tux penguin) randomly alternated each cycle
- Installer auto-configures: pipx + tte, hypridle, Hyprland window rules, hypridle idle listener (5 min default)
- Uninstaller uses marker-based sed cleanup for hyprland.conf and hypridle.conf
- Multi-monitor support: screensaver spawns on every connected monitor
- Dismiss via keypress or focus change; all instances exit together
- Menu entry "Screensaver" added to My Scripts in launcher.sh

---

### [0.6.0] - 2026-02-01

#### Added
- **TUI Visual Refresh** — Enhanced look and UX using more Gum features
- State colors in theme: `THEME_SUCCESS` (green), `THEME_WARNING` (orange), `THEME_ERROR` (red), `THEME_ACCENT` (purple)
- Spinner types: `SPINNER_INSTALL` (dot), `SPINNER_UPDATE` (globe), `SPINNER_CLEANUP` (pulse), `SPINNER_DOWNLOAD` (moon)
- Boxed section headers with rounded borders (`show_subheader()` now uses `gum style --border rounded`)
- New theme functions:
  - `themed_choose_stdin()` — single-select from stdin for dynamic lists
  - `themed_filter()` — fuzzy search with styled indicator
  - `themed_spin()` — styled spinner with configurable animation type
  - `themed_pager()` — soft-wrap pager for long output
  - `show_keyhints()` — keyboard hint display
  - `show_preview_box()` — boxed preview for installation selections
- Service Manager now uses `gum filter` for fuzzy-searchable service list
- Service status view now uses `gum pager` for scrollable output
- System Update/Cleanup now show animated spinners during operations
- Installation preview boxes in all app menus (AI, Browsers, Gaming, Media, Dev Tools)

#### Changed
- `lib/theme.sh` bumped to v0.2.0
- `lib/helpers.sh` bumped to v0.3.0 — print functions now use `gum style` with theme colors
- System Info now displays in a styled box with aligned labels
- `run_with_spinner()` in package-manager.sh now uses `themed_spin()`

#### Fixed
- Theming inconsistency: `launcher.sh` cleanup confirm now uses `themed_confirm()`
- Theming inconsistency: `service-manager.sh` now uses themed wrappers
- Theming inconsistency: `spicetify/install.sh` now uses `themed_choose()`

---

### [0.5.9] - 2026-02-01

#### Added
- Ghostty terminal script bundle (`scripts/ghostty/`)
- Kitty terminal script bundle (`scripts/kitty/`)
- Both terminals include: Catppuccin Mocha, Tokyo Night, HackTheBox themes
- Desktop-aware default terminal setup (GNOME, COSMIC, Hyprland/Sway/X11)
- Menu entries in My Scripts for "Terminal - ghostty" and "Terminal - kitty"

---

### [0.5.8] - 2026-01-30

#### Added
- Docker Compose to Dev Tools menu (separate from Docker engine)
- `install_docker_compose_fallback()` - downloads from GitHub when apt package unavailable

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

### [2.0.0] - 2026-02-03

#### Fixed
- `install.sh`: Detects conflicting `.bashrc` configs (oh-my-bash, bash-it, distro frameworks) and replaces with clean config (backup saved as `~/.bashrc.pre-litebash`)

---

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

### [1.7.0] - 2026-02-03

#### Fixed
- `install.sh`: Detects conflicting `.zshrc` configs (oh-my-zsh, Powerlevel10k, CachyOS/distro frameworks) and replaces with clean config (backup saved as `~/.zshrc.pre-litezsh`)
- `litezsh.zsh`: Now explicitly disables `CORRECT` and `CORRECT_ALL` options to override distro defaults

---

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

## scripts/fastfetch

### [1.1.0] - 2026-02-04

#### Changed
- **Layout reworked**: replaced half-box borders with tree-style connectors and colored section headers
- Section headers: `╭─ System`, `├─ Desktop`, `├─ Hardware` with per-section colors (yellow/blue/green)
- Tree connectors: `├` on all items, `╰` closing on last item (Disk)
- Removed box-drawing borders (`┌──┐`, `├──┤`, `└──┘`) that only closed on separator lines

---

### [1.0.0] - 2026-02-04
- Initial release
- Custom fastfetch config with nerd font icons
- Color-coded sections: yellow (system), blue (desktop), green (hardware)
- Small distro ASCII logo, color palette strip
- Installer uses shared `lib/terminal-install.sh` for `safe_symlink`

---

## scripts/terminal

### [1.2.0] - 2026-02-04

#### Changed
- Refactored to use shared `lib/terminal-install.sh` (was 287 lines, now 69)

---

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

### [1.3.0] - 2026-02-04

#### Changed
- Refactored to use shared `lib/terminal-install.sh` (was 275 lines, now 61)

---

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

---

## scripts/ghostty

### [1.1.0] - 2026-02-04

#### Changed
- Refactored to use shared `lib/terminal-install.sh` (was 293 lines, now 79)

---

### [1.0.0] - 2026-02-01
- Initial release
- Shell-agnostic: works with bash, zsh, fish, or any shell
- Works on both X11 and Wayland
- Themes: Catppuccin Mocha (default), Tokyo Night, HackTheBox
- Iosevka Nerd Font installation
- Desktop-aware default terminal setup (GNOME, COSMIC, Hyprland/Sway/X11)

---

## scripts/kitty

### [1.1.0] - 2026-02-04

#### Changed
- Refactored to use shared `lib/terminal-install.sh` (was 275 lines, now 61)

---

### [1.0.0] - 2026-02-01
- Initial release
- Shell-agnostic: works with bash, zsh, fish, or any shell
- Works on both X11 and Wayland
- Themes: Catppuccin Mocha (default), Tokyo Night, HackTheBox
- Iosevka Nerd Font installation
- Desktop-aware default terminal setup (GNOME, COSMIC, Hyprland/Sway/X11)

---

## scripts/screensaver

### [1.0.1] - 2026-02-04

#### Fixed
- hypridle `on-timeout` now uses full path (`$HOME/.local/bin/mypctools-screensaver-launch`) — hypridle's PATH doesn't include `~/.local/bin`, so the bare command name was silently failing
- Both screensaver scripts now prepend `~/.local/bin` to PATH so `tte` and `mypctools-screensaver-cmd` are findable regardless of inherited environment

---

### [1.0.0] - 2026-02-03
- Initial release
- Omarchy-style terminal screensaver using tte (Terminal Text Effects)
- Alacritty fullscreen on all Hyprland monitors via window rules
- Random tte effects over two ASCII art files (LINUX GANG, Tux)
- Hyprland 0.53+ windowrule syntax (`fullscreen on`, `no_anim on`, `border_size 0`)
- hypridle integration for idle auto-trigger (300s default)
- Multi-monitor: spawns on every monitor, all instances exit together on keypress/focus loss
- Installs pipx + terminaltexteffects, hypridle (if missing)
- Marker-based config injection for clean uninstall (`>>> mypctools-screensaver >>>`)

