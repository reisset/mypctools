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

## Features

- **Install Apps** - Browsers, gaming, media, dev tools, CLI utilities
- **My Scripts** - Personal bash configs, screensavers, and more
- **System Setup** - System info and tweaks
- Cross-distro support (Debian/Ubuntu and Arch-based)
- Smart package detection (skips already-installed apps)
- Fallback installers for packages needing repos/keys (Brave, VSCode, Spotify)

## Included Scripts

This repo consolidates content from:

- **[mybash](https://github.com/reisset/mybash)** → `scripts/bash/` - Bash shell setup and configs
- **[myscreensavers](https://github.com/reisset/myscreensavers)** → `scripts/screensavers/` - Terminal screensaver scripts
- **[claudesetup](https://github.com/reisset/claudesetup)** → `scripts/claude/` - Claude Code preferences and skills
- **[mypowershell](https://github.com/reisset/mypowershell)** → `windows/powershell/` - Windows PowerShell configs (reference)

## Requirements

- Bash
- [Gum](https://github.com/charmbracelet/gum) (installed automatically by `install.sh`)
