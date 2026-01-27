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
| dysk | — | Disk usage (filesystem info) |
| dust | — | Disk usage (directory sizes) |
| gh | — | GitHub CLI |

### Terminal Themes (foot only)
- **Catppuccin Mocha** (default) — Warm, pastel colors
- **Tokyo Night** — Cool blues and purples
- **HackTheBox** — Green hacker aesthetic

## Installation

LiteBash is part of the **mypctools** TUI.

```bash
# Via mypctools (recommended)
mypctools
# Navigate to: Scripts → LiteBash Shell
# Optionally: Scripts → LiteBash Terminal (Wayland only)
```

### Manual Installation

If running standalone outside mypctools:

```bash
# Shell config (works everywhere)
./shell/install.sh

# Terminal config (Wayland only)
./terminal/install.sh
```

Both components are independent — install one or both.

## Theme Switching

Re-run the terminal installer via mypctools and select a different theme, or manually edit `~/.config/foot/foot.ini` and replace the `[colors]` section with one from `terminal/themes/`.

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
# Via mypctools
mypctools
# Navigate to: Scripts → LiteBash Shell → Uninstall
# Navigate to: Scripts → LiteBash Terminal → Uninstall

# Or manually
./shell/uninstall.sh
./terminal/uninstall.sh
```

## Quick Reference

After install, type `tools` to see the command reference.

## License

MIT - see root LICENSE file.
