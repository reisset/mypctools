# mypctools

A personal TUI for managing scripts and app installations across Linux systems. Built with [Bubble Tea](https://github.com/charmbracelet/bubbletea).

## Quick Start

```bash
curl -fsSL https://raw.githubusercontent.com/reisset/mypctools/main/install.sh | bash
mypctools
```

Uninstall:
```bash
curl -fsSL https://raw.githubusercontent.com/reisset/mypctools/main/uninstall.sh | bash
```

## What It Does

### Install Apps

One menu to install apps across distros. Uses native package managers first, falls back to Flatpak or custom installers when needed.

| Category | Apps |
|----------|------|
| Browsers | Brave, Firefox, Chrome, Zen |
| Gaming | Steam, Lutris, Heroic, ProtonUp-Qt |
| Media | Spotify, VLC, OBS, Discord |
| Dev Tools | Docker, Docker Compose, LazyDocker, Lazygit, VSCode, Cursor, .NET SDK 10, Python |
| AI Tools | OpenCode, Claude Code, Mistral Vibe, Ollama, LM Studio |

CLI tools (btop, bat, eza, zoxide, fzf, ripgrep, fd, etc.) are included in the LiteBash and LiteZsh script bundles.

### My Scripts

Bundled script collections with install/uninstall options:

- **LiteBash** - Speed-focused bash environment with modern CLI tools (eza, bat, ripgrep, fd, zoxide, dust, dysk, lazygit, yazi).
- **LiteZsh** - Zsh counterpart to LiteBash with native syntax highlighting, autosuggestions, and arrow-key completion. Auto-sets zsh as default shell.
- **Terminal - foot** - Wayland terminal with curated themes (Catppuccin Mocha, Tokyo Night, HackTheBox). Shell-agnostic.
- **Terminal - alacritty** - X11/Wayland terminal with the same themes. Shell-agnostic.
- **Terminal - ghostty** - X11/Wayland terminal with the same themes. Shell-agnostic.
- **Terminal - kitty** - X11/Wayland terminal with the same themes. Shell-agnostic.
- **Fastfetch** - Custom fastfetch config with boxed layout, nerd font icons, and compact distro logo.
- **Screensaver** - Terminal screensaver via hypridle + Terminal Text Effects. Hyprland only.
- **Spicetify Theme** - Spotify theming with StarryNight or text themes. Native Spotify installs only.
- **Claude Setup** - Claude Code custom skills (pdf, docx, xlsx, pptx, bloat-remover, brainstorming, writing-clearly-and-concisely) and statusline

### System Setup

- Full System Update - one-click apt/pacman/dnf upgrade
- System Cleanup - remove orphans, clear caches, empty trash
- Service Manager - TUI for systemctl services (common services table + fuzzy search across all services)
- System Info - fastfetch-style details (OS, kernel, CPU, GPU, memory, disk, packages)

### CLI Flags

```bash
mypctools --help      # Usage info
mypctools --version   # Version number
```

Updates are checked automatically on launch.

## How Package Installation Works

```
Native (apt/pacman/dnf) → Flatpak → Custom fallback
```

The installer tries each method in order and stops at the first success. Custom fallbacks handle apps that need special setup:

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
- x86_64 or arm64 architecture
- Internet connection for installs

## Building from Source

```bash
git clone https://github.com/reisset/mypctools.git
cd mypctools/tui
go build -o mypctools ./main.go
./mypctools
```

## License

MIT - see [LICENSE](LICENSE).
