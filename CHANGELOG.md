# Changelog

All notable changes to mypctools.

---

## [0.36.0] - 2026-05-07

### Changed
- **Zen UI redesign**: Complete visual overhaul. Single DefaultCyan palette (all other themes removed). Cyan `│` accent bar replaces arrow cursor for selected items. Content floats centered without box wrappers. MYPCTOOLS logo renders with per-character cyan→blue→purple gradient and a character-by-character reveal animation on launch. Loading states use a shimmer scanning-window animation; completion screens use a staggered fade-up reveal.
- **Header**: Sub-screens show `← Title` (muted arrow + white bold title) instead of breadcrumb pills.
- **Footer**: Single centered line with ` · ` separator; key in blue bold, description in muted. No divider line.
- **Service manager**: Context-aware Start/Stop and Enable/Disable actions; Back item fully navigable with separator-offset cursor logic.
- **Script menu**: Installed state shows Reinstall + Uninstall; Back is navigable.
- **Main menu**: Added `q` to quit.

### Removed
- **Theme picker**: `screen/themepicker` deleted. All palette variants except DefaultCyan removed from `theme/theme.go`.
- **Box wrappers**: `ui.Box()` and all `BoxStyle`/`BoxActiveStyle`/`BoxTitleStyle` calls removed.
- **Spinner**: Replaced with shimmer animation in cleanup and pull-update screens.

---

## [0.35.0] - 2026-05-07

### Removed
- **Fedora/RHEL support**: Dropped entirely — project now targets CachyOS and Debian/Ubuntu only. Removed all `dnf` code paths across `lib/`, `tui/internal/cmd/`, `tui/internal/system/`, and all script installers.

### Fixed
- **gnome-ubuntu**: D-Bus session guard, per-package AUR install loop, paru install instructions, GNOME 47+ key detection, idempotency short-circuit.
- **lib/distro-detect.sh**: Word-boundary `ID_LIKE` matching; hard-error on unsupported distro; no longer sources `/etc/os-release`.
- **lib/tools-install.sh**: GitHub rate-limit detection, `mkdir -p` before binary install, 3-attempt retry with backoff.
- **lib/symlink.sh**: `safe_symlink` now accepts directories; auto-creates parent directories.
- **tui/selfupdate**: 60s HTTP timeout; `sha256sum -b` format (3-field `*filename`) handled correctly.
- **tui/system/service**: `ListAllServices` uses native Go parsing; `ServiceExists` checks stdout for unit name.
- **tui/bundle/detect**: `IsInstalled` uses `os.Lstat` so broken symlink markers report correctly.
- **tui/bundle/registry**: Spicetify marker updated to `config-xpui.ini` (stable across upstream updates).
- **tui/screen/exec**: Success path no longer sets `m.done = true` (removes ghost View frame).
- **litezsh/install.sh**: Clean-zshrc replacement now prompts before overwriting; added INT/TERM trap.

---

## [0.34.0] - 2026-05-07

### Changed
- **Terminal font**: Switched to UbuntuMono Nerd Font across alacritty and kitty. Ptyxis now delegates to GNOME system monospace font.

### Removed
- **Ghostty and foot bundles**: Removed. Supported terminals are now alacritty, kitty, and ptyxis.

---

## [0.33.0] - 2026-05-01

### Removed
- **Install Apps feature**: Removed the "Install Apps" menu item, four screens, and `internal/pkg/` package (~1,420 LOC). Main menu now focuses on My Scripts, System Setup, and updates.

---

<details>
<summary>Earlier releases (v0.22.0–v0.31.0)</summary>

**v0.31.0** (2026-03-29) — Responsive TUI: boxes clamp to terminal width; long lists viewport-windowed; "terminal too small" guard below 40×10.

**v0.29.4** (2026-03-29) — gnome-ubuntu: CachyOS Show Apps icon; one-shot autostart to re-apply extension settings after first login.

**v0.29.3** (2026-03-29) — gnome-ubuntu: tiling-assistant, Super+arrows tiling, Alt+Tab window switching, dock polish, Nautilus/desktop defaults.

**v0.29.2** (2026-03-23) — gnome-ubuntu bundle: Yaru-dark, Ubuntu fonts, dash-to-dock for Arch.

**v0.29.1** (2026-03-17) — Auto-sync config bundles after pull update (`AutoSync` field + `bundle.SyncInstalled()`).

**v0.29.0** (2026-03-17) — Statusline context bar: 10-block Unicode bar color-coded by usage.

**v0.28.0** (2026-03-14) — Tool install fixes: tldr download, GitHub rate-limit detection, `GITHUB_TOKEN` support, LiteBash switched to symlinks.

**v0.27.0** (2026-02-12) — Boxed sub-menus with rounded borders; 4 new themes (Dracula, Nord, Gruvbox, Rosé Pine).

**v0.26.x** (2026-02-06–12) — Scripts screen alignment fixes; two-line list items with descriptions; labeled separators; removed highlight bar + breadcrumb pill backgrounds.

**v0.25.0** (2026-02-06) — Gradient logo; j/k vim navigation; animated spinner; uninstall confirmation; toast messages; script descriptions.

**v0.24.x** (2026-02-05–06) — Self-update checksum verification; service manager context-aware actions; app install improvements; ShortHelp on all screens.

**v0.23.0** (2026-02-05) — Removed System Info screen.

**v0.22.0** (2026-02-05) — UI/UX overhaul: consistent item widths; removed vim keybinds and q-to-quit; simplified footer.

**v0.21.0** (2026-02-05) — Go TUI only (removed Gum bash TUI); `curl|bash` installer; binary distribution via GitHub Releases.

</details>
