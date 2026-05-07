<div align="center">

# mypctools

**A TUI for managing scripts and system setup across Linux systems.**

Built with [Bubble Tea](https://github.com/charmbracelet/bubbletea) by Charm.

[![License](https://img.shields.io/badge/license-MIT-blue?style=for-the-badge&labelColor=0a0a0c)](LICENSE)
[![Go](https://img.shields.io/badge/go-1.22%2B-00ADD8?style=for-the-badge&logo=go&logoColor=white&labelColor=0a0a0c)](https://go.dev)

</div>

---

## Quick Start

```bash
curl -fsSL https://raw.githubusercontent.com/reisset/mypctools/main/install.sh | bash
mypctools
```

Uninstall: `curl -fsSL https://raw.githubusercontent.com/reisset/mypctools/main/uninstall.sh | bash`

---

## My Scripts

- **LiteBash** — Bash with modern CLI tools (eza, bat, ripgrep, fd, zoxide, dust, dysk, lazygit, yazi).
- **LiteZsh** — Zsh with syntax highlighting, autosuggestions, arrow-key completion. Sets zsh as default.
- **Alacritty / Kitty / Ptyxis** — Terminal configs. Themes: Catppuccin Mocha, Tokyo Night, HackTheBox, Ubuntu. Ptyxis is Arch only.
- **Fastfetch** — Tree-style layout, nerd font icons.
- **Screensaver** — hypridle + Terminal Text Effects. Hyprland only.
- **GNOME Ubuntu** — Ubuntu GNOME defaults (Yaru, dock, fonts) for Arch.
- **Spicetify** — StarryNight theme for native Spotify.
- **Claude Setup** — Claude Code skills and statusline.

## System Setup

Full system update, cleanup, and systemd service manager built in.

---

## Requirements

Linux (CachyOS or Debian/Ubuntu), x86_64 or arm64.

<details>
<summary>Build from Source</summary>

```bash
git clone https://github.com/reisset/mypctools.git
cd mypctools/tui
go build -o ~/.local/bin/mypctools ./main.go
```

</details>

---

<div align="center">
MIT — <a href="https://github.com/reisset">Reisset</a>
</div>
