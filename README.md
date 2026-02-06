# mypctools

A TUI for managing scripts and app installations across Linux systems. Built with [Bubble Tea](https://github.com/charmbracelet/bubbletea).

## Quick Start

```bash
curl -fsSL https://raw.githubusercontent.com/reisset/mypctools/main/install.sh | bash
mypctools
```

Uninstall:
```bash
curl -fsSL https://raw.githubusercontent.com/reisset/mypctools/main/uninstall.sh | bash
```

## Features

### Install Apps

Install apps from a single menu. The installer tries native package managers first, then Flatpak, then custom fallbacks.

| Category | Apps |
|----------|------|
| AI Tools | OpenCode, Claude Code, Mistral Vibe, Ollama, LM Studio |
| Browsers | Brave, Firefox, Chromium, Zen |
| Gaming | Steam, Lutris, Heroic, ProtonUp-Qt |
| Media | Discord, Spotify, VLC, MPV |
| Dev Tools | Docker, Docker Compose, LazyDocker, Lazygit, VSCode, Cursor, .NET SDK, Python |

LiteBash and LiteZsh also install these CLI tools: btop, bat, eza, fzf, ripgrep, fd, zoxide, lazygit, dust, dysk, yazi, starship, tldr, glow, micro, and github-cli.

### My Scripts

Script bundles you can install or uninstall:

- **LiteBash** — Bash with modern CLI tools (eza, bat, ripgrep, fd, zoxide, dust, dysk, lazygit, yazi). Fast startup.
- **LiteZsh** — Zsh with syntax highlighting, autosuggestions, and arrow-key completion. Sets zsh as default shell.
- **Terminal — foot** — Wayland terminal config. Themes: Catppuccin Mocha, Tokyo Night, HackTheBox.
- **Terminal — alacritty** — X11/Wayland terminal config. Same themes.
- **Terminal — ghostty** — X11/Wayland terminal config. Same themes.
- **Terminal — kitty** — X11/Wayland terminal config. Same themes.
- **Fastfetch** — Tree-style layout with nerd font icons and compact distro logo.
- **Screensaver** — Terminal screensaver via hypridle and Terminal Text Effects. Hyprland only.
- **Spicetify** — StarryNight theme for native Spotify.
- **Claude Setup** — Claude Code skills (pdf, docx, xlsx, pptx, bloat-remover, brainstorming, writing-clearly-and-concisely) and statusline.

### System Setup

- **Full System Update** — Runs apt, pacman, or dnf upgrade.
- **System Cleanup** — Removes orphaned packages, clears caches, empties trash.
- **Service Manager** — Browse or search systemd services.
- **Theme** — Switch between DefaultCyan, CatppuccinMocha, and TokyoNight.

### CLI

```bash
mypctools --help      # Usage
mypctools --version   # Version
mypctools update      # Update binary and scripts
```

The app checks for updates at launch.

## Package Installation Order

```
Native (apt/pacman/dnf) → Flatpak → Custom fallback
```

The installer stops at the first method that succeeds. Custom fallbacks handle apps that require special setup:

| App | Fallback Method |
|-----|-----------------|
| Brave | Official install script |
| Zen | Official install script |
| Discord | .deb download |
| Spotify | Spotify apt repo |
| Docker Compose | GitHub binary release |
| LazyDocker | GitHub binary release |
| Lazygit | GitHub binary release |
| VSCode | Microsoft apt repo |
| Cursor | AppImage download |
| OpenCode | Official install script |
| Claude Code | Official install script |
| Mistral Vibe | Official install script |
| Ollama | Official install script |
| LM Studio | AppImage download |

## Requirements

- Linux (Debian/Ubuntu, Arch, or Fedora-based)
- x86_64 or arm64

## Build from Source

```bash
git clone https://github.com/reisset/mypctools.git
cd mypctools/tui
go build -o mypctools ./main.go
./mypctools
```

## License

MIT — see [LICENSE](LICENSE).
