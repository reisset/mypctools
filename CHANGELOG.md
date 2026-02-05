# Changelog

All notable changes to mypctools.

---

## [0.24.3] - 2026-02-05

### Security
- **Self-update checksum verification**: Binary downloads now verified against SHA256 checksums from `checksums.txt` in the release. Gracefully skips if checksums file isn't published yet. Uses `os.CreateTemp` instead of predictable temp filename.
- **Log file permissions**: Changed from 0644 to 0600 (no longer world-readable)

### Fixed
- **Fedora package names**: Removed incorrect fallback that used Debian apt package names with dnf. Fedora now only uses the explicit `DnfPkg` field for installs and detection.
- **Package detection TUI bleed**: `pacman -Q`, `dpkg -s`, and `rpm -q` output now redirected to `io.Discard` to prevent error messages from leaking into the TUI.
- **Esc handler**: Unified to dispatch `PopScreenMsg` instead of duplicating stack manipulation logic.
- **ASCII icon collision**: `Dot` icon changed from `*` to `.` (was identical to `Check`)
- **Logging performance**: `os.MkdirAll` now runs once via `sync.Once` instead of on every log write

### Improved
- **ShortHelp on all screens**: Added contextual footer hints (`enter select`, `enter apply`, etc.) to all menu screens that previously showed no help text
- **Unit tests**: Added 18 tests for `pkg/install.go` and `pkg/detect.go` covering install command generation, Fedora fix, method descriptions, command detection, and install priority

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
- CI/CD via `.github/workflows/release.yml` — builds binaries on tag push

---

## Pre-release development (v0.4.0–v0.20.0)

<details>
<summary>Go TUI build-up and bash TUI history (2026-01-25 to 2026-02-05)</summary>

- **v0.20.0** — UI overhaul: full-width highlight bars, breadcrumbs, nerd font checkboxes, btop-style boxes, cached styles
- **v0.19.0** — Performance: flatpak cache, menu item cache, style caching
- **v0.18.0** — Operation logging, desktop notifications, Go TUI feature-complete
- **v0.17.0** — Pull Updates screen, Theme Picker with swatches, viewport scrolling
- **v0.16.0** — System Setup: update, cleanup, service manager
- **v0.15.0** — App installation: 23 apps, 5 categories, multi-select, install chain (native PM → flatpak → fallback)
- **v0.14.0** — Script bundles via `tea.ExecProcess()`, installation detection
- **v0.13.0** — Bubble Tea scaffolding, 3 themes, nerd font detection, background update check
- **v0.12.0** — All Services browser, operation logging, removed Flatpak Manager
- **v0.10.0–v0.11.0** — Theme system, nerd font icons, service manager, installed badges, notifications
- **v0.8.0–v0.9.0** — Fastfetch bundle, shared libraries, code consolidation
- **v0.5.0–v0.7.0** — Screensaver, terminal bundles (foot, alacritty, ghostty, kitty)
- **v0.4.0–v0.4.9** — LiteZsh, LiteBash, shared tool installer, service manager, system update/cleanup

</details>
