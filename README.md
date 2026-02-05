# mypctools

A personal TUI for managing scripts and app installations across Linux systems. Built with [Bubble Tea](https://github.com/charmbracelet/bubbletea).

## Quick Start

```bash
curl -fsSL https://raw.githubusercontent.com/reisset/mypctools/main/install.sh | bash
mypctools
```

To uninstall:
```bash
curl -fsSL https://raw.githubusercontent.com/reisset/mypctools/main/uninstall.sh | bash
```

## Features

### Install Apps

Install apps across distros from a single menu. The installer tries native package managers first, then Flatpak, then custom installers.

| Category | Apps |
|----------|------|
| Browsers | Brave, Firefox, Chrome, Zen |
| Gaming | Steam, Lutris, Heroic, ProtonUp-Qt |
| Media | Spotify, VLC, OBS, Discord |
| Dev Tools | Docker, Docker Compose, LazyDocker, Lazygit, VSCode, Cursor, .NET SDK 10, Python |
| AI Tools | OpenCode, Claude Code, Mistral Vibe, Ollama, LM Studio |

The LiteBash and LiteZsh bundles include CLI tools: btop, bat, eza, zoxide, fzf, ripgrep, and fd.

### My Scripts

Bundled script collections you can install or uninstall:

- **LiteBash** - Speed-focused bash environment with modern CLI tools (eza, bat, ripgrep, fd, zoxide, dust, dysk, lazygit, yazi).
- **LiteZsh** - Zsh environment with syntax highlighting, autosuggestions, and arrow-key completion. Sets zsh as default shell.
- **Terminal - foot** - Wayland terminal with Catppuccin Mocha, Tokyo Night, and HackTheBox themes.
- **Terminal - alacritty** - X11/Wayland terminal with the same themes.
- **Terminal - ghostty** - X11/Wayland terminal with the same themes.
- **Terminal - kitty** - X11/Wayland terminal with the same themes.
- **Fastfetch** - Custom config with boxed layout, nerd font icons, and compact distro logo.
- **Screensaver** - Terminal screensaver via hypridle and Terminal Text Effects. Hyprland only.
- **Spicetify Theme** - Spotify theming with StarryNight or text themes. Native Spotify only.
- **Claude Setup** - Claude Code custom skills (pdf, docx, xlsx, pptx, bloat-remover, brainstorming, writing-clearly-and-concisely) and statusline.

### System Setup

- **Full System Update** - Run apt, pacman, or dnf upgrade with one click.
- **System Cleanup** - Remove orphaned packages, clear caches, empty trash.
- **Service Manager** - Browse common services or search all services with fuzzy matching.
- **System Info** - View OS, kernel, CPU, GPU, memory, disk, and package details.

### CLI Flags

```bash
mypctools --help      # Show usage
mypctools --version   # Show version
```

The app checks for updates at launch.

## Package Installation Order

```
Native (apt/pacman/dnf) → Flatpak → Custom fallback
```

The installer stops at the first successful method. Custom fallbacks handle apps requiring special setup:

| App | Fallback Method |
|-----|-----------------|
| Brave | Official install script |
| Docker Compose | GitHub binary release |
| VSCode | Microsoft apt repo |
| Spotify | Spotify apt repo |
| LazyDocker | GitHub binary release |
| Lazygit | GitHub binary release |
| Cursor | AppImage download |
| OpenCode | Official install script |
| Claude Code | Official install script |
| Mistral Vibe | Official install script |
| Ollama | Official install script |

## Requirements

- Linux (Debian/Ubuntu, Arch, or Fedora-based)
- x86_64 or arm64
- Internet connection

## Build from Source

```bash
git clone https://github.com/reisset/mypctools.git
cd mypctools/tui
go build -o mypctools ./main.go
./mypctools
```

## License

MIT - see [LICENSE](LICENSE).
