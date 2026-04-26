<div align="center">

# mypctools

**A TUI for managing scripts and app installations across Linux systems.**

Built with [Bubble Tea](https://github.com/charmbracelet/bubbletea) by Charm.

[![License](https://img.shields.io/badge/license-MIT-blue?style=for-the-badge&labelColor=0a0a0c)](LICENSE)
[![Go](https://img.shields.io/badge/go-1.22%2B-00ADD8?style=for-the-badge&logo=go&logoColor=white&labelColor=0a0a0c)](https://go.dev)
[![Bubble Tea](https://img.shields.io/badge/bubble%20tea-TUI-ff75b5?style=for-the-badge&labelColor=0a0a0c)](https://github.com/charmbracelet/bubbletea)

</div>

---

## ✨ Features

| | |
|---|---|
| 🖥️ **Terminal UI** | Navigate with arrow keys or vim bindings — no commands to memorize |
| 📦 **One-Command Install** | `curl \| bash` to install, same to uninstall |
| 🔍 **Smart Package Manager** | Tries apt/pacman/dnf first, then Flatpak, then custom fallback |
| 🛠️ **Script Bundles** | Shell configs, terminal themes, fastfetch, screensaver, and more |
| ⚙️ **System Tools** | Full system update, cleanup, and systemd service manager |
| 🎨 **Themes** | Switch between DefaultCyan, CatppuccinMocha, and TokyoNight |

---

## 🚀 Quick Start

```bash
curl -fsSL https://raw.githubusercontent.com/reisset/mypctools/main/install.sh | bash
mypctools
```

<details>
<summary><strong>Uninstall</strong></summary>

```bash
curl -fsSL https://raw.githubusercontent.com/reisset/mypctools/main/uninstall.sh | bash
```

</details>

---

<img width="939" height="643" alt="Screenshot_2026-02-07_21-30-06" src="https://github.com/user-attachments/assets/0c70b9d4-b094-4b5b-90b7-b929b5d17e76" />

## 📦 Install Apps

Install apps from a single menu. The installer tries native package managers first, then Flatpak, then custom fallbacks.

| Category | Apps |
|----------|------|
| AI Tools | OpenCode, Claude Code, Mistral Vibe, Ollama, LM Studio |
| Browsers | Brave, Firefox, Chromium, Zen |
| Gaming | Steam, Lutris, Heroic, ProtonUp-Qt |
| Media | Discord, Spotify, VLC, MPV |
| Dev Tools | Docker, Docker Compose, LazyDocker, Lazygit, VSCode, Cursor, .NET SDK, Python |

> LiteBash and LiteZsh also install these CLI tools: btop, bat, eza, fzf, ripgrep, fd, zoxide, lazygit, dust, dysk, yazi, starship, tldr, glow, micro, and github-cli.

---

## 🛠️ My Scripts

Script bundles you can install or uninstall:

- **LiteBash** — Bash with modern CLI tools (eza, bat, ripgrep, fd, zoxide, dust, dysk, lazygit, yazi). Fast startup.
- **LiteZsh** — Zsh with syntax highlighting, autosuggestions, and arrow-key completion. Sets zsh as default shell.
- **Terminal — foot** — Wayland terminal config. Themes: Catppuccin Mocha, Tokyo Night, HackTheBox, Ubuntu.
- **Terminal — alacritty** — X11/Wayland terminal config. Same themes.
- **Terminal — ghostty** — X11/Wayland terminal config. Same themes.
- **Terminal — kitty** — X11/Wayland terminal config. Same themes.
- **Terminal — ptyxis** — GNOME terminal config via palettes. Same themes. Arch/Fedora only.
- **Fastfetch** — Tree-style layout with nerd font icons and compact distro logo.
- **Screensaver** — Terminal screensaver via hypridle and Terminal Text Effects. Hyprland only.
- **GNOME Ubuntu** — Ubuntu GNOME defaults (Yaru theme, dock, fonts) for Arch.
- **Spicetify** — StarryNight theme for native Spotify.
- **Claude Setup** — Claude Code skills (pdf-expert, docx-expert, xlsx-expert, pptx-expert, bloat-remover, writing-clearly-and-concisely) and statusline.

---

## ⚙️ System Setup

- **Full System Update** — Runs apt, pacman, or dnf upgrade.
- **System Cleanup** — Removes orphaned packages, clears caches, empties trash.
- **Service Manager** — Browse or search systemd services.
- **Theme** — Switch between DefaultCyan, CatppuccinMocha, and TokyoNight.

---

## 📋 CLI

```bash
mypctools --help      # Usage
mypctools --version   # Version
mypctools update      # Update binary and scripts
```

The app checks for updates at launch.

---

## 🔧 Package Installation Order

```
Native (apt/pacman/dnf) → Flatpak → Custom fallback
```

The installer stops at the first method that succeeds.

<details>
<summary><strong>Custom fallback details</strong></summary>

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

</details>

---

## 🖥️ Requirements

- Linux (Debian/Ubuntu, Arch, or Fedora-based)
- x86_64 or arm64

---

<details>
<summary><strong>🏗️ Build from Source</strong></summary>

```bash
git clone https://github.com/reisset/mypctools.git
cd mypctools/tui
mkdir -p ~/.local/bin
go build -o ~/.local/bin/mypctools ./main.go
mypctools
```

</details>

---

<div align="center">

MIT — see [LICENSE](LICENSE)

Built by [Reisset](https://github.com/reisset)

</div>
