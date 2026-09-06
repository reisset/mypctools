# Changelog

All notable changes to mypctools.

---

## [0.42.1] - 2026-09-05

### Fixed
- **Installs and self-updates could silently fetch the previous release.** Both `install.sh` and the self-updater downloaded from `releases/latest/download`, an alias that can keep serving the *previous* release's assets for some time after a new one publishes. Observed immediately after v0.42.0 shipped: the release API reported `v0.42.0` while `latest/download` still returned the v0.41.0 binary, so a fresh `install.sh` run produced a v0.41.0 install that looked successful. **SHA256 verification cannot catch this** — `checksums.txt` goes stale alongside the binary, so the pair still matches. Both paths now resolve the newest tag via the releases API and download from its explicit `releases/download/<tag>/` URL, falling back to the old alias only if the API is unreachable.

---

## [0.42.0] - 2026-09-05

### Removed
- **System Setup is gone** — full system update, system cleanup, the service manager, and the Nerd Font toggle. That was **1,345 lines, 36% of the Go codebase**, for a feature set that was never used, and it was the riskiest code here: `pacman -Syu`, orphan removal, cache deletion and systemd control. Typing `paru -Syu` beats launching a TUI to run it. Dropping it also removes `bubbles` as a dependency (its only use in the repo was one viewport) and cuts `IconSet` from 18 fields to 5, since 13 were already dead.

### Added
- **Non-interactive CLI** — `mypctools install <bundle>...`, `uninstall`, and `list`, so a fresh machine can be set up in one pasteable line instead of ~19 keypresses and 6 prompts. Bundle names are validated up front, so a typo cannot half-configure a machine; every bundle is attempted even if an earlier one fails, and the exit code is non-zero if any did.
- **`is_noninteractive()` / `confirm()`** in `lib/print.sh`. Headless mode is signalled explicitly via `MYPCTOOLS_NONINTERACTIVE=1` rather than inferred from the tty, because the CLI has a real terminal (so `sudo` can prompt) but must not ask questions.

### Fixed
- **`dysk` installed the wrong architecture.** Its release is a single zip containing every target (`build/<triple>/dysk`, including macOS and armv7), and the installer took the first match — on x86_64 that selected `aarch64-unknown-linux-musl`, installing an ARM64 binary. Now selects the triple matching `uname -m`.
- **`simple_choose` span forever on EOF** — a `while true` loop whose `read` failure was never checked, measured at 552,046 iterations in 5 seconds at 100% CPU. It now takes the first option on EOF, and returns early when non-interactive.
- **`install.sh` failed on machines without `git`.** It hard-required `git`/`curl`/`sha256sum` and installed none of them, so it fell over on stock Ubuntu Server and Raspberry Pi OS images. Missing dependencies are now installed via inline package-manager detection (this runs before the repo clone, so `lib/distro-detect.sh` isn't available yet).
- **`~/.local/bin` was never actually added to PATH** — the installer only printed advice, so `mypctools` was routinely "command not found" immediately after the documented install command. It now appends to `.bashrc`/`.zshrc`/`config.fish` idempotently.
- **`jq` was an uninstalled hard dependency** — the claude bundle exited 1 without it and `statusline.sh` degraded at runtime, yet nothing installed it. Added to the litebash/litezsh base packages, and the claude bundle now installs it.
- **Installers reported success having installed nothing.** With `set -e` deliberately absent, a run where all 8 CLI tools failed still printed "Installation complete!". Failures are now collected and reported, and the script exits non-zero.
- **LiteZsh's `.zshrc` prompt defaulted to No**, which appended its source line to the conflicting rc and still switched the login shell, leaving two configs fighting. It now defaults to Yes; the original is backed up either way.
- **`set_default_terminal` and three uninstall prompts had no EOF guard** and silently answered whatever a failed `read` left behind. All prompts now route through `confirm` with an explicit default.
- **`raspbian` was missing** from the known distro IDs in both `lib/distro-detect.sh` and `tui/internal/cmd/distro.go`; Raspberry Pi OS resolved only via the `ID_LIKE` fallback.

### Changed
- **CLI tools install from the distro package manager first**, falling back to GitHub releases only when no package provides them. All 8 are in the CachyOS repos, so the primary target no longer scrapes release assets at all — removing both the silent-rot failure mode that broke three arm64 patterns for months, and the 7-API-calls-per-run pressure on GitHub's 60/hr unauthenticated limit.
- **Nerd Font icons are auto-detected** (~76µs directory scan) instead of toggled and persisted to a flag file. `MYPCTOOLS_ICONS=nerd|ascii` overrides detection.
- Path validation for bundle scripts is consolidated in `bundle.ScriptPath`, used by the TUI, AutoSync and the CLI alike.

---

## [0.41.0] - 2026-09-05

### Security
- **`install.sh` installed the binary unverified**: the in-app self-updater has verified SHA256 fail-closed since 0.38.0, but the initial install — which runs via `curl | bash` — downloaded the binary with no verification at all, straight to its final path, then made it executable. A truncated or interrupted download left a corrupt executable installed. The download is now staged inside `~/.local/bin` (same filesystem, so the final `mv` is an atomic rename), checked against the published `checksums.txt`, and aborts if the checksum is missing, unreadable, or mismatched.

### Fixed
- **`pacman -Syu --noconfirm` was two bugs in one line**: `--noconfirm` auto-answers prompts to replace or remove packages during a full upgrade, which is the documented way to break an Arch install unattended; and plain `pacman` never updates AUR packages, so anything installed by the `gnome-ubuntu` bundle silently went stale forever. System update now prefers `paru -Syu`, falls back to `pacman -Syu`, and no longer passes `--noconfirm` — a full upgrade will ask for confirmation.
- **Logging double-checked locking was inert**: `ensureLogDir` is only ever reached with `logMu` already held, so the second mutex and the double-check did nothing while technically racing on a plain `bool`. Removed; a failed home-directory lookup still retries on the next call.

### Changed
- **Service listing is ~10x faster**: the list view renders only name and active state, but fetched four subprocesses per service (`list-unit-files`, `is-active`, `is-enabled`, `show`). Across 370 units that was ~1,480 process spawns and roughly 2s of lag. Both states are available in bulk, so listings now parse one `list-unit-files` plus one `list-units` call — 2 subprocesses, ~198ms, verified to produce identical results to the per-service path. `ListAllServices` is replaced by `GetAllServices`; `GetServiceStatus` is unchanged and still backs the detail view, which needs the main PID.
- **CLAUDE.md corrected**: it claimed `go build` hangs and must never be run — it completes in about 0.16s, and the instruction cost every session a needless round-trip. The Design Decisions section also documented curl|bash installers for Ollama, OpenCode, and Mistral Vibe, none of which exist in the repo; it now describes the two that do (starship, spicetify) plus three previously undocumented decisions: the runtime clone is a force-synced mirror, system update prefers paru, and systemctl is batched rather than looped.

---

## [0.40.0] - 2026-09-05

### Fixed
- **Pull updates could brick permanently**: `pullupdate` and the self-updater both ran `git pull --ff-only` against the runtime clone at `~/.local/share/mypctools`. Once the remote history was rewritten the two shared no common ancestor, so every pull failed with `Not possible to fast-forward` and no recovery path existed. Both now use `system.RepoSyncCmd`, which fetches (unshallowing when needed) and hard-resets to `origin/main` — the runtime clone is a read-only mirror, so local divergence is always discarded. Stale tags are force-updated.
- **Self-update was blocked by the same failure**: `Update()` pulls scripts before replacing the binary and aborts on error, so a stranded clone also prevented the binary from ever updating. Existing broken installs must be repaired by re-running `install.sh`.
- **`install.sh` inherited both flaws**: re-runs now force-sync instead of `git pull`, and the initial clone is full-depth rather than `--depth=1`.
- **ARM64 tool installs were silently broken**: three release-asset patterns never matched on `aarch64`. lazygit and glow are goreleaser projects that label ARM assets `arm64`, not `aarch64`; fastfetch is the inverse — `dpkg --print-architecture` reports `arm64` while the published `.deb` is `aarch64`. All patterns verified against live releases on both architectures.

### Changed
- **Go 1.22 → 1.26**: 1.22 had been end-of-life since early 2025. `go.mod`, the CI toolchain pin, and the README badge now agree.
- **Dependencies**: `bubbles` 0.20.0 → 1.0.0, `bubbletea` 1.3.4 → 1.3.10, plus transitive updates (`x/text` 0.3.8 → 0.41.0, `x/sys` 0.30.0 → 0.47.0). `govulncheck` reports zero vulnerabilities, down from one dormant advisory.
- **Release workflow**: all five actions were years behind. `checkout` v4 → v7, `setup-go` v5 → v7, `upload-artifact` v4 → v7, `download-artifact` v4 → v8, and `action-gh-release` **v1 → v3** (v1 ran on the long-retired Node 16 runtime). The download step now uses `merge-multiple: true`, which replaces the per-directory `sha256sum` subshells with a single command while preserving the bare filenames the self-updater matches verbatim.

---

## [0.39.1] - 2026-07-08

### Fixed
- **Empty shimmer guard**: `Shimmer.Tick()` returns nil when text is empty, preventing useless animation ticks.
- **Logging resilience**: Replaced `sync.Once` with retry-safe double-checked init so a transient `UserHomeDir()` failure doesn't permanently disable logging.
- **Receiver consistency**: Unified `systemsetup` screen to pointer receivers (`*Model`) across all `Screen` interface methods.
- **ID_LIKE word-boundary matching**: `distro.go` now tokenizes `ID_LIKE` to prevent substring false-positives (e.g., "debian" matching "debbian").
- **Truncate guard**: `truncate()` in service list defends against `max < 2` to prevent slice-bounds panic.
- **Icon thread safety**: Added `sync.RWMutex` and `GetIcons()` getter to protect the package-level `Icons` variable from data races.
- **Path traversal prevention**: `exec.go` validates `bundle.ID` contains no path separators and action is `install` or `uninstall`.
- **Git update resilience**: `CheckForUpdates` split into separate 5s fetch + 2s rev-list contexts (was shared 3s).
- **Claude installer robustness**: `install.sh` uses `${BASH_SOURCE[0]}` instead of `$0` for correct behavior under `source` or symlinks.
- **Uninstaller safety**: `litebash` and `litezsh` uninstallers now back up `.bashrc`/`.zshrc` before `sed -i`.

---

## [0.38.1] - 2026-06-11

### Chore
- **Dead code cleanup**: Removed unused files (`ui/box.go`, `theme/spacing.go`, `screen/themepicker/`), unused exported symbols (`ClampBoxWidth`, `StatusBadge`, `EnabledBadge`, `AccentStyle`, `SubheaderStyle`, `Palette.Accent`), and 14 unused layout constants.
- **Hardened awk call**: `statusline.sh` now passes `$used_pct` via `awk -v` instead of string interpolation.
- **Panic visibility**: Background update-check goroutine now logs panics to stderr instead of silently swallowing them.
- **Symlink-aware detection**: Bundle install detection uses `os.Stat` instead of `os.Lstat` so broken symlink markers report correctly.

### Removed
- **Dead code**: Removed unused config constants (`LogPath`, `ConfigDir`), unused cached style fields (`primary`, `secondary`, `statusActive`, `statusInactive`, `statusError`), three unused status-style accessors (`StatusActiveStyle`, `StatusInactiveStyle`, `StatusErrorStyle`), unexported `RebuildStyles` (only ever called from `init()`), dead `commands/` directory loops in claude install/uninstall scripts, and scaffolding `reasonix.toml`.
- **Consolidated `ExecDoneMsg`**: Extracted 5 identical `execDoneMsg struct{ err error }` definitions from individual screen packages into a single shared `app.ExecDoneMsg`.
- **Standardized git pull**: `pullupdate` screen now uses `git pull --ff-only` (matching `selfupdate`), replacing the explicit `pull origin main` invocation.

### Changed
- **Nerd Font toggle**: Replaced slow `fc-list` system-wide font scan on startup with a persistent toggle in System Setup. Preference saved to `~/.config/mypctools/nerd-font`. Instantly switches icon set with an on-screen toast.
- **Simplified palette**: Replaced `Palette` struct and `DefaultCyan` var with an anonymous struct — no multi-theme support needed since the theme picker was removed in v0.36.0.

---

## [0.38.0] - 2026-06-01

### Security
- **Self-update SHA256 verification**: Fixed a silent no-op where directory-prefixed filenames in `checksums.txt` (generated by CI) never matched the bare binary name in the updater, causing every update to skip checksum verification. CI now generates bare filenames (`sha256sum` runs inside each artifact directory). Verification is now **fail-closed** — the update aborts if the checksum file is unreachable or the hash mismatches.

### Fixed
- **Self-update ordering**: Scripts are now pulled via `git pull` before the binary is replaced. A pull failure leaves the install in a clean state (old binary + old scripts); previously a pull failure after a successful binary replace left the two out of sync.
- **`esc` confirm bug**: Pressing `esc` at an uninstall confirmation prompt now cancels the confirmation instead of navigating away. Added `HandlesBack() bool` to the `Screen` interface; `scriptmenu` returns `true` when confirming so the root model defers `esc` to the screen.
- **Ptyxis removed**: Deleted `scripts/ptyxis/` and its registry entry. Ptyxis's pre-installed GNOME palettes already cover the use case; the bundle had `AutoSync:true` incorrectly set (it installs a package and patches CachyOS Hello).
- **litebash/litezsh uninstall**: Uninstallers now restore `~/.bashrc.pre-litebash` / `~/.zshrc.pre-litezsh` if the backup exists (written when the installer replaces a conflicting rc). Otherwise the orphaned `export PATH` line added by the clean-rewrite path is stripped.
- **kitty/alacritty uninstall**: Remove the `.theme` sentinel file written by `select_theme` so the empty-config-dir cleanup (`rmdir`) succeeds.
- **spicetify**: Narrowed Spotify directory permissions from `a+wr` (world-writable) to `g+w` (group-write only). The uninstaller now reverts those permissions after `spicetify restore`.
- **distro-detect**: Command-fallback path (when `os-release` ID is unknown but `pacman`/`apt` is found) now also sets `DISTRO_TYPE` correctly. Previously `DISTRO_TYPE` stayed `unknown` while `PKG_MGR` was set, causing bundles that branch on `DISTRO_TYPE` to abort.
- **gofmt**: Fixed unindented `default:` case in `system/update.go` and `system/cleanup.go`; fixed unindented `return DistroUnknown` in `cmd/distro.go`.
- **Version constant**: Bumped `config.Version` from `0.36.0` to `0.38.0` (was lagging behind the `v0.37.0` tag).

---

## [0.37.0] - 2026-05-07

### Fixed
- **Scripts list**: Constrained list width to 72 chars (was full terminal width) and centered the content block and subtitle.
- **Installed badge**: Replaced loud cyan-background pill with a subtle green `✓ installed` text label.
- **Service list**: Unselected rows now render in normal foreground (`#d4d4d4`) instead of muted; header, separator, and viewport centered.
- **Service detail**: Added PID column to stats row (reads `MainPID` via `systemctl show`).
- **Logo**: Double letter-spacing between characters for more visual presence.
- **Screen header**: Added `PaddingLeft(1)` so `← Title` isn't flush against the terminal edge.

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
