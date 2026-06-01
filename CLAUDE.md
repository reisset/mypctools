# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Context

mypctools is a personal Go TUI for managing scripts and system setup across Linux systems. Built with Bubble Tea / Lip Gloss. When researching UI inspiration, produce concrete implementation plans with specific styling values (colors, padding, borders) rather than vague suggestions.

## UI/UX Principles

Default to minimal and concise for all UI text. Never add verbose descriptions to standard menu items — only short descriptions for user-created/custom items. Less is more.

## Workflow

When implementing UI changes from a plan, show a preview of text content (labels, menu items, copy) BEFORE writing code. Ask for approval on wording before implementing.

## Architecture

```
mypctools/
├── tui/                        # Go TUI source (Bubble Tea)
│   ├── main.go
│   ├── go.mod
│   └── internal/
├── scripts/                    # Script bundles with install/uninstall.sh each
│   ├── shared/                 # starship.toml, aliases.sh, TOOLS.md
│   ├── litebash/               # Speed-focused bash (shell config only)
│   ├── litezsh/                # Speed-focused zsh (syntax highlighting, autosuggestions)
│   ├── alacritty/              # alacritty terminal config (X11 + Wayland)
│   ├── kitty/                  # kitty terminal config (X11 + Wayland)
│   ├── fastfetch/              # Custom fastfetch config
│   ├── screensaver/            # hypridle + tte screensaver (Hyprland only)
│   ├── gnome-ubuntu/           # Ubuntu GNOME defaults for Arch (uses paru)
│   ├── claude/                 # Claude Code skills and statusline
│   └── spicetify/              # Spotify theming
├── lib/                        # Bash libraries
│   ├── print.sh                # Zero-dependency print functions (pure ANSI)
│   ├── distro-detect.sh        # Sets DISTRO_TYPE (arch|debian), PKG_MGR, PKG_INSTALL, PKG_UPDATE
│   ├── tools-install.sh        # Shared CLI tool install/uninstall for litebash & litezsh
│   ├── shell-setup.sh          # set_default_shell shared by litebash & litezsh
│   ├── symlink.sh              # safe_symlink() with backup and idempotency
│   └── terminal-install.sh     # Shared lib for terminal emulator installers
├── .github/workflows/release.yml  # Binary releases on tag push
├── install.sh                  # curl|bash installer
└── uninstall.sh
```

## Key Patterns

**Adding a new script bundle**: Create `scripts/<name>/` with `install.sh` and optionally `uninstall.sh`. Register in `tui/internal/bundle/registry.go`. Set `AutoSync: true` for config-only bundles (safe to re-run silently) — leave false for bundles that install packages or have side-effects.

**Shared tooling**: `lib/tools-install.sh` is sourced by both litebash and litezsh for CLI tool installs (zoxide, lazygit, yazi, starship, etc.). The canonical `starship.toml` lives in `scripts/shared/prompt/` and both bundles symlink to it. Shared aliases live in `scripts/shared/shell/aliases.sh`.

## Distro Support

Targets **CachyOS** (primary Arch flavor) and **Debian/Ubuntu**. Fedora is intentionally removed and will not be re-added. `DISTRO_TYPE` values: `arch`, `debian`.

## Code Style

- Simple bash over clever one-liners
- Comments only where code isn't self-explanatory
- On failure, return to menu — don't exit the entire app
- Use `lib/print.sh` for colored output in script installers

## Design Decisions

**curl|bash fallback installers**: Fallbacks for Ollama, OpenCode, Claude Code, and Mistral Vibe pipe directly from official vendor URLs (`curl ... | bash`). Intentional — official trusted installers, simplifies code, acceptable for a personal tool.

## Go TUI (tui/)

**Building locally** (testing only): Claude must NOT run `go build` directly — it hangs in sandboxed environments. Provide the command and ask the user to run it.

```bash
cd ~/mypctools/tui && go build -o ~/.local/bin/mypctools ./main.go
```

**Releasing**: Any change under `tui/` requires a new semver tag. GitHub Actions builds and publishes the binary. The in-app self-updater downloads the new binary + runs `git pull`.

```bash
git tag v0.X.Y && git push origin v0.X.Y
```

Script-only changes (`scripts/`, `lib/`) are safe to push to main without a tag.

**Structure**:
- `tui/internal/app/` — Root model, screen interface, navigation (Navigate/PopScreen)
- `tui/internal/screen/` — Screen implementations (mainmenu, scripts, scriptmenu, exec, update, cleanup, services, pullupdate, systemsetup)
- `tui/internal/bundle/` — Script bundle registry and installation detection
- `tui/internal/theme/` — Single DefaultCyan palette, gradient logo, Lip Gloss styles
- `tui/internal/ui/` — Shared components (list, badges, header, footer, shimmer, fadeup)
- `tui/internal/state/` — Shared state (distro info, terminal size, update count)
- `tui/internal/config/` — Version, log path, config dir constants
- `tui/internal/cmd/` — CLI argument handling
- `tui/internal/logging/` — Operation logging to `~/.local/share/mypctools/mypctools.log`
- `tui/internal/selfupdate/` — Binary self-update with SHA256 verification
- `tui/internal/system/` — System operations (update, cleanup, services, notifications)

**Patterns**:
- Screens implement `app.Screen`: `Init()`, `Update()`, `View()`, `Title()`, `ShortHelp()`
- Navigation: `app.Navigate(screen)` pushes, `app.PopScreen()` pops
- Menu rendering: `ui.RenderList()` — cyan `│` bar highlight, separators, suffixes
- List width: `ListConfig.MaxInnerWidth` controls max content width (default 50, scripts uses 80)
- Separator-injected cursor offset: when a visual separator precedes the last item (Back), use `listCursor = m.cursor + 1`
- Script execution: `tea.ExecProcess()` suspends TUI, gives script full terminal control
- Animations: `ui.Shimmer` for loading states, `ui.FadeUp` for staggered completion reveals
- Toast messages: `app.Toast()` for auto-dismissing post-operation notifications
- Logging: `logging.LogAction()` for all operations; `system.Notify()` for long operations
