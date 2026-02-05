# Changelog

All notable changes to mypctools.

---

## [0.24.2] - 2026-02-05

### Improved
- **Service Manager**: Simplified service detail menu from 7 items to 4 context-aware actions
  - Shows "Start" or "Stop" based on current running state
  - Shows "Enable" or "Disable" based on current boot state
  - Removed redundant "View Status" (status badges already visible)
  - Menu rebuilds dynamically after each action

---

## [0.24.1] - 2026-02-05

### Fixed
- **Critical**: Fixed missing `helpers.sh` reference in `lib/package-manager.sh` and `scripts/spicetify/uninstall.sh` (changed to `print.sh`)
- **Critical**: Fixed nil map panic risk in `parseOSRelease()` — now returns empty map on error
- Added scanner error check in distro detection
- Added panic recovery in background update check goroutine
- Added bounds validation in service manager before accessing services slice
- Fixed theme save error handling (no longer silently ignored)
- Fixed logging error handling in exec screen (logs to stderr on failure)
- Added `init_sudo` loop guard to prevent multiple background sudo refresh loops
- Added `gpg`/`wget` existence checks in VSCode and Spotify fallback installers

### Improved
- Fixed Unicode truncation in service names (now uses rune count)
- Use `strings.Builder` in list rendering for efficiency
- Preallocate slice in `AppsByCategory()`
- Removed unused `user.Current()` call in main menu
- Fixed shebang in `scripts/claude/install.sh` to use `#!/usr/bin/env bash`

---

## [0.24.0] - 2026-02-05

### Added
- **Chromium** browser (apt/pacman/dnf/flatpak)
- **Zen Browser** (AUR/flatpak/curl installer)

---

## [0.23.0] - 2026-02-05

### Removed
- **System Info screen** — Redundant with fastfetch bundle; had ANSI rendering issues

---

## [0.22.0] - 2026-02-05

### UI/UX Overhaul
- Fixed menu items shifting horizontally on hover (consistent width)
- Fixed duplicate "via via pacman" badge text
- Fixed service manager columns running together (ANSI-aware padding)
- Added subtle box around main menu for visual containment

### Streamlined Controls
- Removed vim keybinds (j/k) — arrow keys only
- Removed "q" to quit — use Escape or Ctrl+C
- Simplified footer help text (only context-specific hints)

---

## [0.21.0] - 2026-02-05

### Changed
- **Go TUI is now the only interface** — Removed Gum-based bash TUI entirely
- **New curl|bash installer** — `curl -fsSL https://raw.githubusercontent.com/reisset/mypctools/main/install.sh | bash`
- **Binary distribution** — Pre-built binaries via GitHub Releases (amd64, arm64)
- **Repo cloned to ~/.local/share/mypctools** — Scripts accessed from there

### Added
- `.github/workflows/release.yml` — CI/CD builds binaries on tag push
- `simple_choose()` in `lib/print.sh` — Pure bash menu selection (no gum)

### Removed
- `launcher.sh` — Gum TUI entry point
- `apps/` directory — All 6 app menu scripts (ai.sh, browsers.sh, dev-tools.sh, gaming.sh, media.sh, service-manager.sh)
- `lib/helpers.sh` — Gum-dependent helpers
- `lib/theme.sh` — Gum theming

### Migrated
- `scripts/screensaver/install.sh` — Now uses `lib/print.sh` instead of `lib/helpers.sh`
- `scripts/spicetify/install.sh` — Now uses `lib/print.sh` and `simple_choose()` instead of gum

---

## [0.20.0] - 2026-02-05

### Go TUI Phase 7: UI/UX Overhaul
- Full-width highlight bars on menu selection (lazygit-inspired)
- Inline breadcrumb navigation (`Parent / Current`)
- Nerd font checkboxes with ASCII fallback
- btop-inspired rounded border boxes
- Service status pill badges with background colors
- Responsive main menu logo for narrow terminals
- 15+ cached Lip Gloss styles for performance

---

## [0.19.0] - 2026-02-05

### Performance & Polish
- Flatpak cache (30s) to avoid repeated shell calls
- Menu items cache — only rebuild when update count changes
- Style caching — pre-build all lipgloss styles once
- Fixed duplicate titles, breadcrumb centering, vertical centering threshold

---

## [0.18.0] - 2026-02-04

### Go TUI Phase 6: Final Polish
- Operation logging to `~/.local/share/mypctools/mypctools.log`
- Desktop notifications via `notify-send` for long operations
- **Go TUI now feature-complete** with full bash version parity

---

## [0.17.0] - 2026-02-04

### Go TUI Phase 5: Polish
- Pull Updates screen with `git pull origin main`
- Theme Picker with visual color swatches
- Viewport scrolling for services list (100+ items)

---

## [0.16.0] - 2026-02-04

### Go TUI Phase 4: System Setup
- Full System Update (apt/pacman/dnf)
- System Cleanup with cache clearing prompts
- Service Manager with Common Services table and All Services browser
- System Info with two-column layout

---

## [0.15.0] - 2026-02-04

### Go TUI Phase 3: App Installation
- 23 apps across 5 categories (AI, Browsers, Gaming, Media, Dev Tools)
- Multi-select with checkboxes, installed badges, install method hints
- Sequential installation with progress counter
- Install chain: native PM → flatpak → custom fallback

---

## [0.14.0] - 2026-02-04

### Go TUI Phase 2: Script Bundles
- All 10 script bundles with install/uninstall via `tea.ExecProcess()`
- Installation detection via marker file checks
- Spacebar as alternative to Enter for selection

---

## [0.13.0] - 2026-02-04

### Go TUI Phase 1: Scaffolding
- Bubble Tea architecture with screen stack navigation
- 3 theme presets (DefaultCyan, CatppuccinMocha, TokyoNight)
- Nerd Font detection with ASCII fallback
- Background git update check
- CLI flags: `--help`, `--version`

---

## [0.12.0] - 2026-02-04

- All Services browser with `gum filter` fuzzy search
- Operation logging (`log_action()`)
- Nerd Font detection with ASCII fallback
- Removed Flatpak Manager (flatpak still works as install fallback)

---

## [0.10.0–0.11.0] - 2026-02-04

- Theme system (3 presets saved to `~/.config/mypctools/theme`)
- Nerd Font icons (15 icon variables)
- Service Manager with `gum table` layout
- Installed status badges (✓) on apps and script bundles
- Desktop notifications after long operations

---

## [0.8.0–0.9.0] - 2026-02-04

- **Fastfetch bundle** with tree-style layout
- **Shared libraries**: `lib/print.sh`, `lib/symlink.sh`, `lib/shell-setup.sh`, `lib/terminal-install.sh`
- Major code consolidation (-255 lines)
- Live output for Full System Update

---

## [0.5.0–0.7.0] - 2026-01-29 to 2026-02-03

- **Screensaver bundle** (tte + hypridle integration)
- **Terminal bundles**: foot, alacritty, ghostty, kitty (all with 3 themes)
- Removed `set -e` from 11 scripts (was causing silent failures)
- TUI visual refresh with state colors and fuzzy search

---

## [0.4.0–0.4.9] - 2026-01-25 to 2026-01-28

- **LiteZsh bundle** with syntax highlighting and autosuggestions
- **LiteBash bundle** with modern CLI tools
- `lib/tools-install.sh` shared tool installer
- `scripts/shared/` for aliases and starship config
- Service Manager, Full System Update, System Cleanup
- `--help`/`--version` flags, automatic update check

---

## Script Bundles

| Bundle | Description |
|--------|-------------|
| litebash | Speed-focused bash with eza, bat, ripgrep, fd, zoxide, lazygit, yazi, starship |
| litezsh | Zsh counterpart with syntax highlighting, autosuggestions, arrow-key completion |
| terminal | foot config (Wayland only) with 3 themes |
| alacritty | alacritty config (X11 + Wayland) with 3 themes |
| ghostty | ghostty config (X11 + Wayland) with 3 themes |
| kitty | kitty config (X11 + Wayland) with 3 themes |
| fastfetch | Custom config with tree-style layout |
| screensaver | Terminal screensaver via hypridle + tte (Hyprland only) |
| claude | Claude Code skills and statusline |
| spicetify | Spotify theming (native installs only) |
