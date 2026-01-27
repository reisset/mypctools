# LiteBash

Speed-focused bash environment for Linux power users.

## Philosophy

- **Speed over features** — git_status disabled in prompt, no language version scanning
- **Split architecture** — Shell config works everywhere; terminal config is Wayland-only
- **Modern tools as defaults** — `ls` is eza, `cat` is bat, `grep` is ripgrep

## What's Included

### Tools
| Tool | Replaces | Description |
|------|----------|-------------|
| eza | ls | Modern ls with icons |
| bat | cat | Syntax highlighting |
| ripgrep | grep | Fast search |
| fd | find | Fast file finder |
| fzf | — | Fuzzy finder |
| zoxide | cd | Smart directory jumping |
| btop | top | System monitor |
| lazygit | — | Git TUI |
| micro | vim/nano | Easy terminal editor |
| yazi | — | File manager |
| starship | — | Fast, minimal prompt |
| tealdeer | man | tldr pages |
| glow | — | Markdown renderer |
| dysk | df | Disk usage |
| gh | — | GitHub CLI |

### Terminal Themes (foot only)
- **Catppuccin Mocha** (default) — Warm, pastel colors
- **Tokyo Night** — Cool blues and purples
- **HackTheBox** — Green hacker aesthetic

## Installation

```bash
git clone https://github.com/YOUR_USERNAME/litebash.git
cd litebash

# Shell config (works everywhere)
cd shell && ./install.sh

# Terminal config (Wayland desktops only)
cd ../terminal && ./install.sh
```

Both components are independent — install one or both.

## Theme Switching

Re-run `terminal/install.sh` and select a different theme, or manually edit `~/.config/foot/foot.ini` and replace the `[colors]` section with one from `terminal/themes/`.

## Customization

### Config Locations
- Shell: `~/.local/share/litebash/`
- Starship prompt: `~/.config/starship.toml`
- foot terminal: `~/.config/foot/foot.ini`

### Adding Aliases
Edit `~/.local/share/litebash/aliases.sh`

### Modifying Prompt
Edit `~/.config/starship.toml`. See [Starship docs](https://starship.rs/config/).

## Uninstallation

```bash
cd litebash/shell && ./uninstall.sh
cd ../terminal && ./uninstall.sh
```

## Quick Reference

After install, type `tools` to see the command reference.

## License

MIT - see root LICENSE file.
