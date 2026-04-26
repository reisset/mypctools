# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

mypctools is a personal TUI (Terminal User Interface) for managing scripts and app installations across Linux systems. Built with [Bubble Tea](https://github.com/charmbracelet/bubbletea) by Charm.

See README.md for user documentation and quick start.

## Project Context

This is a Go TUI project. Use Bubble Tea / Lip Gloss patterns. When researching UI inspiration, produce concrete implementation plans with specific styling values (colors, padding, borders) rather than vague suggestions.

## UI/UX Principles

When adding text/descriptions to UI elements, default to minimal and concise. Never add verbose descriptions to standard menu items — only add short descriptions for user-created/custom items. Less is more for TUI interfaces.

## Workflow

When implementing UI changes from a plan, show a preview or summary of text content (labels, descriptions, menu items) BEFORE writing the code. Ask for approval on copy/wording before implementing.

## Architecture

```
mypctools/
├── tui/                        # Go TUI source (Bubble Tea)
│   ├── main.go
│   ├── go.mod
│   └── internal/
├── scripts/                    # Script bundles with install/uninstall.sh each
│   ├── shared/                 # Shared assets used by multiple bundles
│   │   ├── prompt/             # starship.toml (shared prompt config)
│   │   └── shell/              # aliases.sh, TOOLS.md (shared by litebash & litezsh)
│   ├── litebash/               # Speed-focused bash (shell config only)
│   ├── litezsh/                # Speed-focused zsh (syntax highlighting, autosuggestions)
│   ├── terminal/               # foot terminal config (shell-agnostic, Wayland only)
│   ├── alacritty/              # alacritty terminal config (shell-agnostic, X11 + Wayland)
│   ├── ghostty/                # ghostty terminal config (shell-agnostic, X11 + Wayland)
│   ├── kitty/                  # kitty terminal config (shell-agnostic, X11 + Wayland)
│   ├── ptyxis/                 # ptyxis terminal config via palettes (GNOME, Arch/Fedora only)
│   ├── fastfetch/              # Custom fastfetch config with tree-style layout
│   ├── screensaver/            # Terminal screensaver via hypridle + tte (Hyprland only)
│   ├── gnome-ubuntu/             # Ubuntu GNOME defaults (Arch only, uses paru)
│   ├── claude/                 # Claude Code skills and statusline
│   └── spicetify/              # Spotify theming
├── lib/                        # Bash libraries (for script bundles)
│   ├── print.sh                # Zero-dependency print functions (pure ANSI)
│   ├── distro-detect.sh        # Sets DISTRO_TYPE, DISTRO_NAME, PKG_MGR, PKG_INSTALL, PKG_UPDATE
│   ├── tools-install.sh        # Shared CLI tool install/uninstall for litebash & litezsh
│   ├── shell-setup.sh          # Parametric set_default_shell shared by litebash & litezsh
│   ├── symlink.sh              # safe_symlink() with path resolution, backup, idempotency
│   └── terminal-install.sh     # Shared lib for terminal emulator installers
├── .github/workflows/          # CI/CD
│   └── release.yml             # Binary releases on tag push
├── install.sh                  # curl|bash installer (downloads binary + clones repo)
├── uninstall.sh                # Removes binary and ~/.local/share/mypctools
└── README.md
```

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/reisset/mypctools/main/install.sh | bash
```

The installer:
1. Clones the repo to `~/.local/share/mypctools` (for script bundles)
2. Downloads the pre-built binary to `~/.local/bin/mypctools`

## Key Patterns

**Package installation** is handled by the Go TUI in `tui/internal/pkg/`. Apps are registered in `registry.go` with native package names (`AptPkg`, `PacmanPkg`, `DnfPkg`), `FlatpakID`, and `FallbackCmd`. Install priority: native PM → flatpak → fallback command.

**Adding a new script bundle**: Create `scripts/<name>/` with `install.sh` and optionally `uninstall.sh`. Register in `tui/internal/bundle/registry.go`. Set `AutoSync: true` if the bundle is config-only (safe to re-run silently on every update) — leave it false for bundles that install system packages or have side-effects.

**Shared CLI tool installation** uses `lib/tools-install.sh`. Both litebash and litezsh source this lib to avoid duplicating GitHub-release download logic. Key functions:
- `install_all_tools` - installs zoxide, lazygit, tldr, glow, dysk, dust, yazi, starship
- `create_debian_symlinks` - creates bat/fd symlinks on Debian
- `uninstall_local_tools` - removes all tools from `~/.local/bin`
- `install_starship_config` / `uninstall_starship_config` - manages the shared starship.toml symlink

The canonical `starship.toml` lives in `scripts/shared/prompt/` and both bundles symlink to it.

**Shared shell assets** live in `scripts/shared/shell/`:
- `aliases.sh` - 26 aliases shared by litebash and litezsh
- `TOOLS.md` - quick reference for all CLI tools (includes zsh features section)

## Included Script Bundles

- `scripts/litebash/` - Speed-focused bash environment with modern CLI tools (eza, bat, ripgrep, fd, zoxide, lazygit, yazi, starship). Shell config only.
- `scripts/litezsh/` - Zsh counterpart to litebash with native syntax highlighting, autosuggestions, and arrow-key completion. Auto-sets zsh as default shell.
- `scripts/terminal/` - foot terminal config (Wayland only). Shell-agnostic. Themes: Catppuccin Mocha, Tokyo Night, HackTheBox, Ubuntu.
- `scripts/alacritty/` - alacritty terminal config (X11 + Wayland). Shell-agnostic. Same themes.
- `scripts/ghostty/` - ghostty terminal config (X11 + Wayland). Shell-agnostic. Same themes.
- `scripts/kitty/` - kitty terminal config (X11 + Wayland). Shell-agnostic. Same themes.
- `scripts/ptyxis/` - ptyxis terminal config via .palette keyfiles (GNOME, Arch/Fedora only). Same themes. Palettes installed to `~/.local/share/org.gnome.Ptyxis/palettes/`; applied via gsettings.
- `scripts/fastfetch/` - Custom fastfetch config with tree-style layout, nerd font icons, color-coded sections, small distro logo.
- `scripts/screensaver/` - Omarchy-style terminal screensaver using tte (Terminal Text Effects) with hypridle integration. Hyprland only.
- `scripts/gnome-ubuntu/` - Ubuntu GNOME defaults (Yaru theme, dash-to-dock, Ubuntu fonts) for Arch. Uses paru.
- `scripts/claude/` - Claude Code skills (pdf, docx, xlsx, pptx, bloat-remover) and statusline
- `scripts/spicetify/` - Spicetify + StarryNight theme for native Spotify installs

## Distro Support

Tested on Arch-based and Debian/Ubuntu-based distros. Fedora support is partial (uses `DnfPkg` field only — no apt name fallback).
`DISTRO_TYPE` is exported by `lib/distro-detect.sh` and used throughout.

## Code Style

- Simple bash over clever one-liners
- Comments only where code isn't self-explanatory
- On failure, return to menu — don't exit the entire app
- Use `lib/print.sh` for colored output in standalone script installers

## Design Decisions

**curl|bash fallback installers**: The fallback functions for Ollama, OpenCode, Claude Code, and Mistral Vibe pipe directly from official vendor URLs (`curl ... | bash`). This is intentional:
- These are official installers from trusted vendors
- Simplifies code vs download-then-execute pattern
- Acceptable tradeoff for a personal tool

## Go TUI (tui/)

The primary TUI implementation in Go using Bubble Tea.

**Building locally** (testing only): Claude must NOT run `go build` directly — it hangs in sandboxed environments. Provide the command and ask the user to run it.

```bash
cd ~/mypctools/tui && go build -o ~/.local/bin/mypctools ./main.go
```

**Releasing** (required whenever Go TUI code changes): Push a new semver tag. GitHub Actions builds the binary and publishes a GitHub Release. The in-app self-updater (`mypctools` → Update) downloads the new binary + runs `git pull` so all machines stay in sync without manual recompilation.

```bash
git tag v0.X.Y && git push origin v0.X.Y
```

**Rule**: If a change touches any file under `tui/` (Go code), a new release tag MUST be pushed alongside the commit — otherwise the self-updater delivers updated scripts but an old binary that doesn't know about the new features. Script-only changes (under `scripts/`, `lib/`) are safe to push to main without a tag; `git pull` is enough.

**Structure**:
- `tui/internal/app/` — Root model, screen interface, navigation (Navigate/PopScreen)
- `tui/internal/screen/` — Screen implementations (mainmenu, scripts, scriptmenu, exec, update, cleanup, services, apps, applist, appconfirm, appinstall, pullupdate, systemsetup, themepicker)
- `tui/internal/bundle/` — Script bundle registry and installation detection
- `tui/internal/theme/` — Color palettes, gradient logo, Lip Gloss styles, icons
- `tui/internal/ui/` — Shared UI components (list rendering, badges, header, footer, box, checkbox)
- `tui/internal/state/` — Shared state (distro info, terminal size, update count)
- `tui/internal/config/` — User configuration (theme persistence)
- `tui/internal/cmd/` — CLI argument handling
- `tui/internal/logging/` — Operation logging to ~/.local/share/mypctools/mypctools.log
- `tui/internal/selfupdate/` — Binary self-update with SHA256 verification
- `tui/internal/system/` — System operations (update, cleanup, services, notifications)
- `tui/internal/pkg/` — Package installation with apt/pacman/dnf/flatpak support

**Patterns**:
- Screens implement `app.Screen` interface: `Init()`, `Update()`, `View()`, `Title()`, `ShortHelp()`
- Navigation: `app.Navigate(screen)` pushes, `app.PopScreen()` pops, `j/k` vim keys alongside arrows
- Menu rendering: `ui.RenderList()` handles cursors, highlight bars, suffixes, separators, dimming
- List width: `ListConfig.MaxInnerWidth` controls max content width (default 50, scripts uses 80)
- Script descriptions: Shown as muted right-side suffix in scripts screen (from `bundle.Description`)
- Script execution: `tea.ExecProcess()` suspends TUI, gives script full terminal control
- Toast messages: Auto-dismissing notifications after operations (install, update, cleanup)
- Logging: `logging.LogAction()` for all operations (installs, updates, service actions)
- Notifications: `system.Notify()` for long operations (update, cleanup, batch installs)
