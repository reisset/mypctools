# LiteZsh

Speed-focused zsh environment for Linux power users.

Zsh counterpart to [LiteBash](../litebash/). Same tools, same prompt, plus zsh-native features.

## Why Zsh?

LiteBash is fast but bash has limitations. Adding syntax highlighting or autosuggestions to bash requires ble.sh, which adds 100-200ms startup time.

LiteZsh uses zsh's native features:
- **Syntax highlighting** — commands colored as you type (red = invalid)
- **Autosuggestions** — ghost text from history (press → to accept)
- **Better completion** — menu navigation with arrow keys
- **History search** — type partial command, press ↑ to find matches

Total added startup time: ~15-20ms.

## Installation

Via mypctools (recommended):
```bash
mypctools
# Navigate to: Scripts → LiteZsh
```

Manual:
```bash
./install.sh
```

## Terminal Config

Terminal theming is shell-agnostic. Install separately:
```bash
# Via mypctools
mypctools → Scripts → Terminal - foot

# Or manually
../terminal/install.sh
```

## What's Different from LiteBash

| Feature | LiteBash | LiteZsh |
|---------|----------|---------|
| Shell | bash | zsh |
| Syntax highlighting | (slow via ble.sh) | native |
| Autosuggestions | | native |
| Arrow-key completion | | native |
| History substring search | | native |
| Tools | identical | identical |
| Prompt (starship) | identical | identical |

## Customization

### Config Locations
- Shell: `~/.local/share/litezsh/`
- Starship prompt: `~/.config/starship.toml`

### Adding Aliases
Edit the source file at `aliases.zsh` in the repo (symlinked to `~/.local/share/litezsh/`).

### Modifying Prompt
Edit `~/.config/starship.toml`. See [Starship docs](https://starship.rs/config/).

## Uninstallation

```bash
./uninstall.sh
```

This will:
- Remove LiteZsh config
- Remove zsh plugins
- Restore bash as default shell
- Optionally remove CLI tools

## Quick Reference

After install, type `tools` to see the command reference.

## License

MIT - see root LICENSE file.
