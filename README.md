# mypctools

A personal TUI for managing scripts and app installations across Linux systems. Built with [Gum](https://github.com/charmbracelet/gum).

**v0.2.0**

## Quick Start

```bash
git clone https://github.com/reisset/mypctools.git
cd mypctools
./install.sh    # Installs gum, creates symlink
mypctools       # Run from anywhere
```

Uninstall: `./uninstall.sh`

## What It Does

### Install Apps

One menu to install apps across distros. Uses native package managers first, falls back to Flatpak or custom installers when needed.

| Category | Apps |
|----------|------|
| Browsers | Brave, Firefox, Chrome, Zen |
| Gaming | Steam, Lutris, Heroic, ProtonUp-Qt |
| Media | Spotify, VLC, OBS, Discord |
| Dev Tools | Docker, LazyDocker, VSCode, Cursor, .NET SDK, Python |
| CLI Utils | btop, neofetch, bat, eza, zoxide, fzf, Caligula |
| AI Tools | OpenCode, Claude Code, Mistral Vibe, Ollama, LM Studio |

### My Scripts

Bundled script collections with install/uninstall options:

- **Bash Setup** - Kitty terminal, Starship prompt, modern CLI tools (bat, eza, fzf, zoxide). Has `--server` flag for headless installs.
- **Screensavers** - Terminal eye candy (cmatrix, pipes, asciiquarium, etc.)
- **Claude Setup** - Claude Code preferences, CLAUDE.md templates, custom skills

### System Setup

- Detailed system info (fastfetch-style): OS, kernel, CPU, GPU, memory, disk, packages, uptime

### Settings

- Check for updates via git pull
- About info

## How Package Installation Works

```
Native (apt/pacman/dnf) → Flatpak → Custom fallback
```

The installer tries each method in order and stops at the first success. Custom fallbacks handle apps that need special setup:

| App | Fallback Method |
|-----|-----------------|
| Brave | Official install script |
| VSCode | Microsoft apt repo |
| Spotify | Spotify apt repo |
| Caligula | cargo install |
| LazyDocker | GitHub binary release |
| Cursor | AppImage download |
| OpenCode | Official install script |
| Claude Code | Official install script |
| Mistral Vibe | Official install script |
| Ollama | Official install script |

## Project Structure

```
mypctools/
├── launcher.sh              # Main TUI
├── install.sh / uninstall.sh
├── lib/
│   ├── helpers.sh           # Print functions, gum wrappers
│   ├── distro-detect.sh     # Sets DISTRO_TYPE and DISTRO_NAME
│   └── package-manager.sh   # install_package() with fallback chain
├── apps/                    # App category menus
│   ├── ai.sh
│   ├── browsers.sh
│   ├── cli-utils.sh
│   ├── dev-tools.sh
│   ├── gaming.sh
│   └── media.sh
└── scripts/                 # Bundled script collections
    ├── bash/
    ├── screensavers/
    └── claude/
```

## Requirements

- Linux (Debian/Ubuntu, Arch, or Fedora-based)
- Bash
- Internet connection for installs

Gum is installed automatically by `./install.sh`.

## Related Repos

The scripts in this repo were consolidated from:

- [mybash](https://github.com/reisset/mybash) - Bash shell setup
- [myscreensavers](https://github.com/reisset/myscreensavers) - Terminal screensavers
- [claudesetup](https://github.com/reisset/claudesetup) - Claude Code config
- [mypowershell](https://github.com/reisset/mypowershell) - Windows PowerShell (reference only)
