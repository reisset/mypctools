# Changelog

All notable changes to mypctools and its bundled scripts.

> **Maintenance Note**: When fixing bugs, always fix THE SCRIPT, not the user's
> system manually. Scripts must work end-to-end on first run. If a script fails,
> the fix goes in the script—never patch the user's config files directly as a
> workaround. The goal: run once, log out, done.

---

## mypctools

### [0.19.0] - 2026-02-05

#### Fixed
- **Duplicate titles removed** — Sub-screens no longer render their own title since breadcrumb already shows it
- **Breadcrumb centering** — Breadcrumb and boxed title now center properly on all screen widths
- **Vertical centering threshold** — Only center content if less than 70% of screen height (scrolling lists stay at top)

#### Performance
- **Flatpak cache** — Cache `flatpak list` results for 30s to avoid repeated shell calls when checking installed apps
- **Menu items cache** — Main menu only rebuilds items when update count changes
- **Style caching** — Pre-build all lipgloss styles once instead of recreating on every render

---

### [0.18.0] - 2026-02-04

#### Added
- **Go TUI Phase 6: Final Polish** — Operation logging and desktop notifications
  - Logging package (`tui/internal/logging/`) — `LogAction()` appends timestamped entries to `~/.local/share/mypctools/mypctools.log`
  - Notification function (`tui/internal/system/notify.go`) — `Notify()` sends desktop notifications via `notify-send`
  - All operations now logged: app installs, script bundle install/uninstall, system update, system cleanup, service actions
  - Desktop notifications after: system update, system cleanup, batch app installs, script bundle operations

#### Notes
- Go TUI is now feature-complete with full bash version parity
- All 6 phases complete: scaffolding → script bundles → app installation → system setup → polish → final polish

---

### [0.17.0] - 2026-02-04

#### Added
- **Go TUI Phase 5: Polish** — Missing features and viewport scrolling
  - Pull Updates screen (`tui/internal/screen/pullupdate/`) — runs `git pull origin main`, clears update badge on success
  - Theme Picker screen (`tui/internal/screen/themepicker/`) — visual color swatches for all 3 themes, "(current)" indicator
  - Theme option added to System Setup menu
  - Bubbles viewport component for services list scrolling

#### Fixed
- All Services list now scrolls properly — cursor stays visible when navigating 100+ items, scroll indicator `[N/M]` shows position

#### Known Issues
- TUI suspend/resume during sudo operations remains (accepted tradeoff for `tea.ExecProcess()` design)

---

### [0.16.0] - 2026-02-04

#### Added
- **Go TUI Phase 4: System Setup** — "System Setup" menu now functional
  - System package (`tui/internal/system/`) with distro-aware commands for update, cleanup, service management, and system info gathering
  - System Setup menu screen with 4 options: Full System Update, System Cleanup, Service Manager, System Info
  - Full System Update runs `apt update && apt upgrade` / `pacman -Syu` / `dnf upgrade` via `tea.ExecProcess()`
  - System Cleanup runs package cleanup, then prompts for user cache (thumbnails, trash) clearing
  - Service Manager with Common Services (table view with Status/Enabled columns) and All Services browser
  - Service detail screen with Start/Stop/Restart/Enable/Disable/View Status actions
  - System Info display with two-column lipgloss layout (system info + hardware info)

#### Known Issues
- Same jarring TUI suspend behavior during sudo operations (see 0.14.0)
- ~~All Services list has no viewport scrolling~~ — Fixed in 0.17.0

---

### [0.15.0] - 2026-02-04

#### Added
- **Go TUI Phase 3: App Installation** — "Install Apps" menu now functional
  - App registry (`tui/internal/pkg/`) with 23 apps across 5 categories (AI Tools, Browsers, Gaming, Media, Dev Tools)
  - Installation detection via command check, native package manager query, and flatpak list
  - Category menu with app counts
  - Multi-select app list with `[ ]`/`[x]` checkboxes, installed ✓ badges, install method hints
  - Space to toggle selection, `a` to select all uninstalled, `n` to clear selection
  - Confirmation screen previewing selected apps before install
  - Sequential installation via `tea.ExecProcess()` with progress counter `[1/5]`
  - Summary screen with succeeded/failed counts
  - Install chain: native PM (apt/pacman/dnf) → flatpak → custom fallback command

#### Known Issues
- Same jarring TUI suspend behavior during installs (see 0.14.0) — future improvement to show inline progress

---

### [0.14.0] - 2026-02-04

#### Added
- **Go TUI Phase 2: Script Bundles** — "My Scripts" menu now functional
  - Bundle registry (`tui/internal/bundle/`) with all 10 script bundles (litebash, litezsh, terminal, alacritty, ghostty, kitty, fastfetch, screensaver, claude, spicetify)
  - Installation detection via marker file checks (same paths as bash `is_script_installed()`)
  - Scripts list screen with j/k navigation and green ✓ badges for installed bundles
  - Per-bundle submenu: Install / Uninstall / Back
  - Script execution via `tea.ExecProcess()` — suspends TUI, gives script full terminal control (sudo prompts work), shows success/failure on return
  - Spacebar as alternative to Enter for menu selection

#### Fixed
- `go.mod` version changed from 1.25 (nonexistent) to 1.22

#### Known Issues
- Sudo password prompts cause jarring visual transition (TUI suspends → terminal → TUI resumes) — inherent to `tea.ExecProcess()` design
- Menu items not perfectly centered — polish deferred to later phase

---

### [0.13.0] - 2026-02-04

#### Added
- **Go/Bubble Tea TUI rewrite scaffolding** — Phase 1 of a parallel TUI implementation in `tui/` directory
  - Binary: `tui/mypctools-tui` (4.9MB standalone, no runtime deps)
  - Core architecture: screen stack with push/pop navigation, root model delegates Update/View to active screen
  - Theme system: 3 presets (DefaultCyan, CatppuccinMocha, TokyoNight) matching bash version, Lip Gloss styles
  - Nerd Font detection with ASCII fallback icons (matches bash `lib/theme.sh`)
  - Distro detection mirroring `lib/distro-detect.sh` logic
  - Main menu screen with logo, system info line, update badge, j/k navigation
  - CLI flags: `--help`, `--version`
  - Background git update check (same `fetch origin main` + `rev-list --count` pattern)

#### Notes
- Go TUI and bash TUI coexist — user can choose either version
- Dependencies: `github.com/charmbracelet/bubbletea`, `lipgloss`, `bubbles`
- Issue during initial setup: `go mod tidy` hung in the default shell environment; resolved by running Go commands in a clean `env -i` subshell

---

### [0.12.0] - 2026-02-04

#### Added
- **All Services browser** — Service Manager now has "All Services" option that dynamically scans all system services via `systemctl list-unit-files` and presents them with `gum filter` for fuzzy search
- **Operation logging** — `log_action()` in `lib/helpers.sh` appends timestamped entries to `~/.local/share/mypctools/mypctools.log` for package installs, system update/cleanup, and service actions
- **Nerd Font detection** — `_has_nerd_font()` in `lib/theme.sh` checks for Nerd Fonts via `fc-list`; falls back to ASCII icons (`>>`, `<>`, `::`, etc.) when no Nerd Font is installed

#### Changed
- Service Manager: "Browse Services" renamed to "Common Services", "Enter Custom Service" replaced with "All Services"
- Removed redundant `clear` after `themed_pause` in system update, cleanup, and service action handlers (loop already clears at top)

#### Removed
- **Flatpak Manager** — removed `apps/flatpak-manager.sh` and menu entry from System Setup (flatpak installs still work as fallback in package-manager)
- `ICON_FLATPAK` from `lib/theme.sh`

---

### [0.11.0] - 2026-02-04

#### Added
- **Installed status badges** — `✓` next to already-installed apps in all multi-select menus (AI, Browsers, Gaming, Media, Dev Tools). Uses `app_label()` in `lib/package-manager.sh`
- **Script bundle status badges** — `✓` next to installed bundles in My Scripts menu. Uses `is_script_installed()` and `script_label()` in `lib/helpers.sh`
- **Theme preview with color swatches** — visual preview of all 7 colors for each theme preset shown above the theme selector. Uses `show_theme_preview()` in `lib/theme.sh`
- **Custom service entry** — "Enter Custom Service" option in Service Manager using `gum input`, with validation against `systemctl list-unit-files`
- **Flatpak Manager** — new section under System Setup with List Installed Apps (`gum table`), Update All (live output), and Clean Unused Runtimes (confirm dialog). Graceful skip if flatpak missing
- `ICON_FLATPAK` in `lib/theme.sh`

#### Changed
- Service Manager now has sub-menu: Browse Services / Enter Custom Service / Back
- All app menus strip `✓` badge before matching case statements

---

### [0.10.0] - 2026-02-04

#### Added
- **Theme system** — 3 color presets: Default (Cyan), Catppuccin Mocha, Tokyo Night. Saved to `~/.config/mypctools/theme`, selectable from System Setup > Theme
- **Nerd Font icons** — 15 icon variables in `lib/theme.sh`, used across main menu, Install Apps, System Setup, and Back buttons
- **`gum table`** for Service Manager — proper columnar layout with Service/Status/Enabled columns, replaces fuzzy filter
- **`show_divider()`** — auto-sizing horizontal separator (replaces hardcoded strings)
- **`notify_done()`** — desktop notifications via `notify-send` after system update, cleanup, and batch installs
- **Side-by-side System Info** — `gum join --horizontal` layout on wide terminals (>= 90 cols), falls back to single column on narrow
- **Step counter** in `install_all_tools()` — `[1/8]` through `[8/8]` progress during tool installation

#### Changed
- **`lib/theme.sh` rewritten** — theme presets with hex colors, GUM_* env vars auto-exported (simplifies all themed_* wrappers), `--padding "0 1"` on choose/filter
- All `themed_choose`, `themed_spin` wrappers simplified — styling now inherited from GUM_* env vars
- All case statements use glob matching (`*"Back"`) to handle icon-prefixed menu items
- Service Manager: 6 raw `read -rp` calls replaced with `themed_pause`
- Version bumped to 0.10.0 (launcher was stuck at 0.6.0)

#### Removed
- Dead functions from `lib/theme.sh`: `themed_choose_stdin()`, `themed_filter()`, `themed_spin_live()` (never called)
- Unused spinner constants from `lib/theme.sh`: `SPINNER_UPDATE`, `SPINNER_DOWNLOAD`
- Unused `log_info()` and `log_error()` from `lib/helpers.sh`
- Unused `confirm()` from `scripts/claude/uninstall.sh`
- Unused variables from `scripts/screensaver/install.sh`: `SCREENSAVER_CLASS`, `MARKER_END`
- Unnecessary sudo prompt from `scripts/terminal/uninstall.sh` (sudo was never used)
- Redundant case branches in `scripts/litezsh/install.sh` `install_zsh()` (all branches were identical)

---

### [0.9.0] - 2026-02-04

#### Added
- **`lib/print.sh`** — shared print functions (zero gum dependency), sourced by 12+ scripts
- **`lib/symlink.sh`** — single canonical `safe_symlink` with path resolution, backup, and idempotency
- **`lib/shell-setup.sh`** — parametric `set_default_shell` shared by litebash and litezsh
- **`init_sudo()`** in `lib/print.sh` — sudo prompt + background keepalive for long-running installers
- **`themed_pause()`** in `lib/theme.sh` — styled replacement for raw `read -rp "Press Enter..."`
- **`show_install_summary()`** in `lib/theme.sh` — succeeded/failed counts after batch installs
- **Breadcrumb navigation** — submenus show parent context (e.g., "Install Apps > AI Tools")
- **Batch progress indicators** — `[1/5] Installing...` during multi-package installs
- `lib/distro-detect.sh` now exports `PKG_MGR`, `PKG_INSTALL`, `PKG_UPDATE`

#### Changed
- **Full System Update now shows live output** — streamed package manager output replaces hidden spinner
- **Major code consolidation** — 22 files changed, net -255 lines removed
- Print functions standardized to `print_status`/`print_success`/`print_warning`/`print_error` across project
- All app menus show install summary instead of generic "Done!"

#### Fixed
- Unquoted `$orphans` variable in `launcher.sh` — never expanded inside single-quoted `bash -c`
- Trash/thumbnail deletion without confirmation — System Cleanup now asks before clearing

#### Removed
- Duplicate `detect_distro()`, `safe_symlink()`, `init_sudo()`, `set_default_shell()`, and inline print functions from 12+ files (now in shared libs)

---

### [0.8.0] - 2026-02-04

#### Added
- **Fastfetch script bundle** (`scripts/fastfetch/`) — custom config with tree-style layout, nerd font icons, color-coded sections, small distro logo
- **`lib/terminal-install.sh`** — shared lib for terminal emulator installers (`safe_symlink`, `detect_distro`, `select_theme`, `install_font`, `set_default_terminal`)
- `show_script_submenu()` in `launcher.sh` — generic handler for all script bundle menus

#### Changed
- Script menu consolidated: 9 identical menu blocks replaced with single-line `show_script_submenu()` calls (launcher.sh: 669 → 419 lines)
- Terminal installers (foot, alacritty, ghostty, kitty) refactored to source `lib/terminal-install.sh` (~1130 → ~490 total lines)

---

### [0.7.0] - 2026-02-03

#### Added
- **Screensaver script bundle** (`scripts/screensaver/`) — Omarchy-style terminal screensaver using tte (Terminal Text Effects)
- Fullscreen Alacritty on all Hyprland monitors with random tte effects over ASCII art
- hypridle integration for idle auto-trigger (300s default)
- Multi-monitor support: all instances exit together on keypress/focus loss
- Marker-based config injection for clean uninstall

---

### [0.6.0] - 2026-02-01

#### Added
- **TUI Visual Refresh** — state colors, spinner types, boxed section headers, fuzzy search
- Theme functions: `themed_spin()`, `themed_pager()`, `show_preview_box()`
- Service Manager now uses `gum filter` for fuzzy-searchable service list
- Installation preview boxes in all app menus

---

### [0.5.0–0.5.9] - 2026-01-29 to 2026-02-01

Rapid iteration period. Key additions: **Ghostty** and **Kitty** terminal bundles, **Alacritty** bundle, Docker Compose + Lazygit in Dev Tools. Key fixes: removed `set -e` from 11 scripts (was causing silent failures), introduced `safe_symlink()` pattern, standardized font sizes, fixed `command_exists()` empty string bug. Removed CLI Utils menu (redundant with LiteBash/LiteZsh).

---

### [0.4.0–0.4.9] - 2026-01-25 to 2026-01-28

Foundation period. Key additions: **LiteZsh** bundle, **Terminal - foot** as standalone bundle, `lib/tools-install.sh` shared tool installer, `scripts/shared/` for aliases and starship config, Service Manager TUI, Full System Update, System Cleanup, `--help`/`--version` flags, automatic update check on launch. Removed old Bash Setup and Screensavers bundles, Settings menu, unused functions.

---

### [0.3.0–0.3.1]

Fedora/dnf support, Discord in Media menu, `ensure_sudo()` helper, gum spin hanging fixes.

---

## Script Bundles

### litebash
- **2.0.0** (2026-02-03) — Conflicting `.bashrc` detection (oh-my-bash, bash-it, distro frameworks); backup saved as `~/.bashrc.pre-litebash`
- **1.0.0** (2026-01-25) — Initial release: eza, bat, ripgrep, fd, fzf, zoxide, btop, lazygit, micro, yazi, starship, tealdeer, glow, dysk, dust, gh

### litezsh
- **1.7.0** (2026-02-03) — Conflicting `.zshrc` detection (oh-my-zsh, Powerlevel10k, CachyOS frameworks); explicitly disables `CORRECT`/`CORRECT_ALL`
- **1.0.0** (2026-01-28) — Initial release: same tools as litebash, plus zsh-syntax-highlighting, zsh-autosuggestions, arrow-key completion, history substring search

### Terminal emulators (foot, alacritty, ghostty, kitty)
- All refactored to use `lib/terminal-install.sh` in 0.8.0 (~275 lines each → ~65 lines)
- All ship themes: Catppuccin Mocha (default), Tokyo Night, HackTheBox
- foot: Wayland only. alacritty/ghostty/kitty: X11 + Wayland

### fastfetch
- **1.1.0** (2026-02-04) — Tree-style connectors replacing box borders
- **1.0.0** (2026-02-04) — Initial release

### screensaver
- **1.0.1** (2026-02-04) — hypridle PATH fix (full path to launch script)
- **1.0.0** (2026-02-03) — Initial release
