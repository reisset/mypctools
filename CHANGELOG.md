# Changelog

All notable changes to mypctools.

---

## [0.31.0] - 2026-03-29

### Fixed
- **Responsive TUI on small terminals**: Boxes (menus, script lists, app lists) now clamp their width to the terminal width, preventing text wrap and garbled layouts on narrow windows.
- **Vertical overflow / items disappearing at top**: Long lists are now windowed to the available height — the visible slice stays centered on the cursor, so items never render off-screen. The main menu progressively hides the logo and system info lines on short terminals.
- **"Terminal too small" guard**: Terminals narrower than 40 columns or shorter than 10 rows show a centered resize prompt instead of a broken layout.

---

## [0.29.4] - 2026-03-29

### Added
- **gnome-ubuntu: CachyOS Show Apps icon**: The "Show Apps" button in the dock now shows the CachyOS logo. dash-to-dock uses `view-app-grid-{session-mode}-symbolic` — on a standard GNOME session the mode is `user`, so we install `/usr/share/icons/cachyos.svg` as a user Yaru icon override. Uninstall cleans it up.
- **gnome-ubuntu: One-shot autostart for extension settings**: On a fresh install, tiling-assistant and dash-to-dock run first-time initialization on the first login and reset keys to schema defaults. A one-shot autostart script re-applies all extension settings ~8s after login and removes itself.

### Fixed
- **gnome-ubuntu: tiling-assistant popup not appearing**: `org.gnome.mutter edge-tiling` was set to `true`, causing mutter to handle drag-to-edge events and bypass tiling-assistant's popup entirely. Set to `false` so tiling-assistant owns all edge tiling.
- **gnome-ubuntu: tiling-assistant focus hint**: Enabled `focus-hint 1` with border style — subtle colored outline on focused tiled windows matching Ubuntu's behavior (uses orange accent color already configured).
- **gnome-ubuntu: tiling popup across workspaces**: Added `tiling-popup-all-workspace true` so the tile-selection popup appears regardless of which workspace windows are on.
- **gnome-ubuntu: dock running indicators**: Added `running-indicator-style DOTS` — Ubuntu uses dots under running app icons, not the default style.
- **gnome-ubuntu: dock background shape**: Added `custom-theme-shrink true` — pill-shaped dock background around icon groups instead of a full rectangle.
- **gnome-ubuntu: dock always-visible panel mode**: Added `dock-fixed true` for true panel behavior (was relying only on autohide/intellihide false).
- **gnome-ubuntu: dock transparency**: Added `transparency-mode FIXED` and `background-opacity 0.8` — Ubuntu's semi-transparent dock style.
- **gnome-ubuntu: tiling-assistant not in uninstall**: tiling-assistant was never disabled by the uninstaller. Added to the disabled-extensions list.

---

## [0.29.3] - 2026-03-29

### Added
- **gnome-ubuntu bundle**: Installs `gnome-shell-extension-tiling-assistant` and `gnome-extensions-app`.
- **Window tiling (Super+arrows)**: Tiling-assistant extension enabled with Ubuntu-style keybindings — `Super+Left/Right` for half-tiling, `Super+Up` to maximize, `Super+Down` to restore.
- **Mutter defaults**: `edge-tiling`, `dynamic-workspaces`, and `workspaces-only-on-primary` now set to match Ubuntu.
- **Alt+Tab window switching**: `switch-windows` bound to `Alt+Tab` (individual windows, not app groups), `Super+Tab` for app switching — matches Ubuntu's feel vs stock GNOME.
- **Super+D show desktop**: Added keybinding Ubuntu ships by default.
- **Never sleep on AC**: `sleep-inactive-ac-timeout 0` — Ubuntu's default, stock GNOME sleeps after 15 min.
- **Nautilus defaults**: Small icon zoom level (sort-directories-first was removed in GNOME 43+).
- **Desktop icons defaults**: No trash/volumes on desktop, icons anchor to bottom-right corner.
- **Orange accent color**: Ubuntu's brand accent (`org.gnome.desktop.interface accent-color 'orange'`).

### Fixed
- **gnome-ubuntu dash-to-dock config**: Updated dock defaults to match Ubuntu's actual behavior — left-side, full-height, always-visible dock. Previous config used bottom/autohide.
- **button-layout**: Removed `appmenu` from left side of titlebar (now `:minimize,maximize,close`).
- **Font antialiasing**: Added `rgba` subpixel antialiasing to match Ubuntu.
- **action-middle-click-titlebar**: Set to `lower` (Ubuntu default).

---

## [0.29.2] - 2026-03-23

### Added
- **GNOME Ubuntu bundle**: Reproduces Ubuntu's GNOME defaults on Arch (Yaru-dark theme, Ubuntu fonts, dash-to-dock, window button layout). Installs via paru, discovers extension UUIDs at runtime.

### Fixed
- **Missing Ubuntu defaults**: Added `color-scheme prefer-dark` (libadwaita apps), hot corners off, tap-to-click, dock show-apps-at-top, and click-to-minimize.
- **Dash-to-dock hotkey conflict**: Disabled dock hot-keys and shortcut that stole Super+Q from custom GNOME keybindings.
- **Dock gsettings errors**: Added stderr suppression for dock settings that fail when the extension schema isn't loaded yet.
- **Terminal bundle sudo during auto-sync**: Terminal install scripts (alacritty, foot, ghostty, kitty) no longer prompt for sudo when the terminal is already installed, fixing broken auto-sync after pull updates.
- **paru sudo prompt in TUI**: Pre-cache sudo credentials before paru runs in gnome-ubuntu installer so the password prompt works correctly inside the TUI.

---

## [0.29.1] - 2026-03-17

### Added
- **Auto-sync config bundles on update**: After a successful pull update, `install.sh` is automatically re-run for all installed config-only bundles (foot terminal, alacritty, ghostty, kitty, fastfetch, claude). Tool-installer bundles (litebash, litezsh) and side-effect bundles (screensaver, spicetify) are skipped. Toast and done screen report which configs were synced.
- **`AutoSync` field on Bundle**: New boolean field in the bundle registry marks bundles safe for automatic re-install after a repo update.
- **`bundle.SyncInstalled()`**: New function that iterates all installed AutoSync bundles and silently re-runs their `install.sh`.

---

## [0.29.0] - 2026-03-17

### Changed
- **Statusline context bar**: Replaced numeric `CTX: 34%` with a 10-block Unicode bar (`CTX: ▓▓▓░░░░░░░`). Filled blocks are color-coded green/yellow/red by usage threshold; empty blocks render in muted gray.

### Removed
- **Brainstorming skill**: Dropped from the claude bundle — superseded by the `superpowers:brainstorming` skill from the official superpowers plugin.

---

## [0.28.0] - 2026-03-14

### Fixed
- **tldr (tealdeer) download broken**: Raw binary release pattern couldn't distinguish binary from `.sha256` checksum file — gave tldr a dedicated install function with proper filtering
- **Silent extraction failures**: `tar`/`unzip` errors in `tools-install.sh` now abort instead of continuing silently
- **VS Code fallback**: Switched from `wget` + hardcoded `/tmp` to `curl` + `mktemp` for consistency and safety
- **Redundant sed**: Removed no-op `s/x86_64/x86_64/` from lazydocker and lazygit fallback commands
- **Stale app install status**: App list now refreshes installed status when returning from installation screen
- **foot default theme**: Changed from `hackthebox` to `catppuccin-mocha` to align with alacritty, ghostty, and kitty defaults
- **README**: Fixed Go version badge (1.23 → 1.22), fixed Claude skill names to match actual directory names

### Added
- **GitHub API rate-limit detection**: `tools-install.sh` now detects rate limiting and shows a clear error message instead of cryptic "Could not find release"
- **GITHUB_TOKEN support**: Tool installs use `GITHUB_TOKEN` env var for authenticated API calls when available (raises rate limit from 60 to 5,000 req/hr)

### Changed
- **LiteBash config handling**: Switched from copying config files to symlinks (matching litezsh), so configs stay in sync with repo updates
- Removed unused `running` field from appinstall and `started` field from exec screen models

---

## [0.27.0] - 2026-02-12

### Added
- **Boxed sub-menus**: All sub-menu screens now render inside rounded border boxes (matching main menu style) — scripts, apps, system setup, script menu, app list, theme picker
- **4 new themes**: Dracula, Nord, Gruvbox Dark, Rosé Pine — each with full palette, logo gradient, and color swatches in the theme picker
- **White text highlight**: Selected/focused menu items now render as bright white bold text, contrasting clearly against theme-colored unselected items

### Fixed
- **Statusline token inflation**: Token count was double-counting by adding `total_output_tokens` on top of `total_input_tokens` (which already represents cumulative context size)

### Changed
- **Script menu layout**: Bundle title, description, and install status now render inside the box alongside the install/uninstall actions
- **Sub-menu box widths**: Standard menus use 64-char boxes, scripts and app list use 84-char wide boxes for descriptions and badges

---

## [0.26.2] - 2026-02-12

### Removed
- **Highlight bar**: Removed the cyan background rectangle on hovered/selected menu items across all screens — selection now shown with arrow cursor + bold text only
- **Breadcrumb pill**: Removed dark background box from breadcrumb navigation — text styling preserved
- **Footer key pills**: Removed dark background boxes from footer help keys — plain bold text instead
- Dead style code: `HighlightFull` list config, `ListHighlightStyle`, `HelpKeyPillStyle`, `BreadcrumbStyle`

### Fixed
- **Selection centering bug**: Selected items no longer shift horizontally when navigating menus — all lines now render at consistent width

---

## [0.26.1] - 2026-02-06

### Fixed
- **Scripts screen alignment**: Removed centering from script names and descriptions — all items now left-align consistently regardless of checkmark presence
- **Italic on hover removed**: Selected script descriptions no longer turn italic
- **Description indentation**: Descriptions now have matching left padding so they align under the label text

### Removed
- Deleted `lib/package-manager.sh` — dead code, never sourced; Go TUI has its own `tui/internal/pkg/` implementation
- Removed unused Go functions: `ui.TitledBox`, `ui.RenderSimpleList`, `ui.SkipSeparator`, `ui.CheckMark`, `system.ServiceStatusCmd`, `pkg.AppByID`
- Removed unused Go type `pkg.CategoryInfo`
- Removed unused theme style accessors: `LogoStyle`, `MenuCursorStyle`, `MenuItemStyle`, `BadgeInstalledStyle`, `BoxContentStyle`
- Removed unused spacing constants: `SpaceXS`, `SpaceSM`, `SpaceMD`, `SpaceLG`, `SpaceXL`
- Removed empty `tui/internal/screen/system/` directory (leftover from v0.23.0)
- Removed git-tracked binary `tui/mypctools` from index

### Fixed
- Updated `config.Version` from stale `0.24.4` to current
- Added `tui/mypctools` to `.gitignore` (was only ignoring `tui/mypctools-tui`)

---

## [0.26.0] - 2026-02-06

### Added
- **Two-line list items**: List items now support a `Description` field rendered as a centered muted line below the label — scripts screen uses this for cleaner layout
- **Centered description layout**: Script name + checkmark are centered over the description text for visual balance
- **Labeled section separators**: Separators can now display section headers (e.g. `── Settings ──────`) — used in System Setup menu
- **Centralized layout constants**: All hardcoded widths, column sizes, and separator strings extracted to `theme/layout.go` for consistency

### Changed
- **Scripts screen**: Descriptions moved from cramped single-line suffixes to dedicated second line below each bundle name
- **Service table**: Column widths now reference `theme.ServiceCol*` constants instead of hardcoded values

---

## [0.25.0] - 2026-02-06

### Added
- **Gradient logo**: Main menu logo now renders with a per-theme color gradient (6 colors across 6 lines)
- **Section separators**: Thin `───` dividers in main menu (before Exit) and system setup (before Theme) for visual grouping
- **j/k vim navigation**: All menu screens now support `j`/`k` for up/down alongside arrow keys
- **Animated spinner**: Cache-clearing phase in System Cleanup now shows a spinning indicator
- **Uninstall confirmation**: Script menu now asks "Uninstall {bundle}? y/n" before proceeding
- **Toast messages**: Successful operations (script install/uninstall, system update, cleanup) auto-dismiss with a brief toast notification instead of "press any key"
- **Script descriptions**: My Scripts screen shows short descriptions to the right of each bundle name with checkmarks in a fixed column for easy scanning
- **Configurable list width**: `ListConfig.MaxInnerWidth` allows wider content areas (used by scripts screen at 80 chars)

### Removed
- **Menu descriptions**: Removed verbose description text from main menu, app categories, and system setup (menus are self-explanatory)

---

## [0.24.6] - 2026-02-06

### Fixed
- **Terminal theme selection broken**: Removed codepath that sourced nonexistent `lib/theme.sh` when `gum` was installed — text-based theme picker now always used
- **Starship config removed on partial uninstall**: Uninstalling litebash or litezsh no longer removes `~/.config/starship.toml` if the sibling bundle is still installed
- **LiteZsh continues after zsh install failure**: Installer now aborts early if zsh cannot be installed, instead of proceeding to install plugins and set default shell

---

## [0.24.5] - 2026-02-06

### Fixed
- **Screensaver uninstall broken**: `uninstall.sh` sourced nonexistent `lib/helpers.sh` — changed to `lib/print.sh`
- **Release checksums**: CI workflow now generates and uploads `checksums.txt` so self-update SHA256 verification actually works
- **Installer dependency check**: `install.sh` now verifies `git` and `curl` are available before use
- **Main menu cursor safety**: Cursor clamped after dynamic menu rebuild to prevent out-of-bounds when "Pull Updates" item disappears
- **Stale help text**: Removed leftover "q quit" from main menu footer (q was removed in v0.22.0)

---

## [0.24.4] - 2026-02-05

### Fixed
- **Fastfetch on Debian/Ubuntu/Pop!_OS**: Added GitHub release `.deb` download fallback when `apt install fastfetch` fails (package not in default repos)
- **Fastfetch false success**: Install script no longer reports "Installation complete!" when fastfetch fails to install
- **Brave on Debian/Pop!_OS**: Now uses official curl installer (`dl.brave.com`) instead of Flatpak fallback

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
