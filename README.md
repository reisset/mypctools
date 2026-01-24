# mypctools

A personal TUI (Terminal User Interface) for managing scripts and app installations across Linux systems.

Built with [Gum](https://github.com/charmbracelet/gum) by Charm.

## Quick Start

```bash
git clone https://github.com/reisset/mypctools.git
cd mypctools
./install.sh
mypctools
```

To uninstall: `./uninstall.sh`

## Features

- **Install Apps** - Browsers, gaming, media, dev tools, CLI utilities
- **My Scripts** - Personal bash configs, screensavers, Claude Code setup (all with install/uninstall)
- **System Setup** - System info and tweaks
- Cross-distro support (Debian/Ubuntu and Arch-based)
- Smart package detection (skips already-installed apps)
- Spinner UI during installations with graceful Ctrl+C handling
- Fallback installers with retry/timeout for packages needing repos (Brave, VSCode, Spotify)

## Included Scripts

This repo consolidates content from:

| Script | Source | Description |
|--------|--------|-------------|
| `scripts/bash/` | [mybash](https://github.com/reisset/mybash) | Bash shell setup, Kitty, Starship, modern CLI tools |
| `scripts/screensavers/` | [myscreensavers](https://github.com/reisset/myscreensavers) | Terminal screensavers (cmatrix, pipes, etc.) |
| `scripts/claude/` | [claudesetup](https://github.com/reisset/claudesetup) | Claude Code preferences and skills |
| `windows/powershell/` | [mypowershell](https://github.com/reisset/mypowershell) | Windows PowerShell configs (reference only) |

## Requirements

- Bash
- Linux (Debian/Ubuntu or Arch-based)
- [Gum](https://github.com/charmbracelet/gum) (installed automatically)
