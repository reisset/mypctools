# LiteBash

Speed-focused bash environment for Linux power users.

## Philosophy

- **Speed over features** — git_status disabled in prompt, no language version scanning
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

## Installation

LiteBash is part of the **mypctools** TUI.

```bash
# Via mypctools (recommended)
mypctools
# Navigate to: Scripts → LiteBash
```

### Manual Installation

```bash
./install.sh
```

## Terminal Config

Terminal theming (foot) is shell-agnostic and lives separately at `../terminal/`.

```bash
# Via mypctools
mypctools → Scripts → Terminal - foot

# Or manually
../terminal/install.sh
```

## Customization

### Config Locations
- Shell: `~/.local/share/litebash/`
- Starship prompt: `~/.config/starship.toml`

### Adding Aliases
Edit `~/.local/share/litebash/aliases.sh`

### Modifying Prompt
Edit `~/.config/starship.toml`. See [Starship docs](https://starship.rs/config/).

## Uninstallation

```bash
# Via mypctools
mypctools
# Navigate to: Scripts → LiteBash → Uninstall

# Or manually
./uninstall.sh
```

## Quick Reference

After install, type `tools` to see the command reference.

## License

MIT - see root LICENSE file.
