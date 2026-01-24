# 🖥️ myscreensavers

Omarchy-style terminal screensavers for Linux.

Auto-activates after 5 minutes of idle. Displays animated ASCII art using [TerminalTextEffects](https://github.com/ChrisBuilds/terminaltexteffects).

**Supported systems:**
- Ubuntu/Debian (GNOME, KDE, X11)
- Arch/CachyOS/Manjaro (Hyprland, Sway, GNOME, KDE, X11)
- Fedora (GNOME, KDE, X11)

## 🚀 Install

```bash
git clone git@github.com:reisset/myscreensavers.git ~/myscreensavers
cd ~/myscreensavers
./install.sh
```

Daemon starts automatically on login.

## Usage

**Test manually** (Ctrl+C to exit):
```bash
./bin/screensaver
```

**Check daemon:**
```bash
systemctl --user status screensaver-daemon
journalctl --user -u screensaver-daemon -f
```

## ⚙️ Configuration

Create a config file at `~/.config/myscreensavers/config` (see `config.example`):

```bash
mkdir -p ~/.config/myscreensavers
cp config.example ~/.config/myscreensavers/config
```

### Options

| Setting | Default | Description |
|---------|---------|-------------|
| `IDLE_TIMEOUT_MS` | `300000` | Idle time before activation (ms) |
| `CHECK_INTERVAL` | `5` | Polling interval (seconds) |
| `PREFERRED_TERMINAL` | auto | Force specific terminal |
| `LOCK_ON_IDLE` | `false` | Lock screen before screensaver |
| `ART_DIR` | `config/ascii_art` | Custom ASCII art directory |
| `EFFECTS` | (built-in) | Custom effects array |

### Examples

**10-minute timeout with screen lock:**
```bash
IDLE_TIMEOUT_MS=600000
LOCK_ON_IDLE=true
```

**Custom effects only:**
```bash
EFFECTS=(matrix rain blackhole fireworks)
```

### ASCII Art
Add your own `.txt` files to `config/ascii_art/` or set `ART_DIR` in config.

## How it works

```
┌─────────────────────────────────────────────────────────────┐
│  screensaver-daemon                                         │
│  └─ detects desktop environment (GNOME, Hyprland, etc.)     │
│  └─ uses appropriate idle detection:                        │
│      • GNOME: DBus IdleMonitor (polling)                    │
│      • Hyprland/Sway: swayidle (event-based)                │
│      • X11/KDE: xprintidle (polling)                        │
│  └─ CHECKS BATTERY: if discharging, skips launch            │
│  └─ when idle > 5 min, launches fullscreen terminal         │
│  └─ terminal runs: tte <effect> < random_art.txt            │
│  └─ on user activity, INSTANTLY kills the terminal          │
└─────────────────────────────────────────────────────────────┘
```

**Requirements:**
- Linux with systemd
- `sudo` access (installer auto-installs dependencies)
- Terminal: `kitty`, `ghostty`, `foot`, `alacritty`, or `gnome-terminal`

**Desktop-specific dependencies:**

| Desktop | Package | Install |
|---------|---------|---------|
| GNOME | dbus (usually preinstalled) | - |
| Hyprland/Sway | swayidle | `sudo pacman -S swayidle` |
| X11/KDE | xprintidle | `sudo pacman -S xprintidle` |

## Troubleshooting

- **"No supported terminal found"?** Install one of: `kitty`, `ghostty`, `foot`, `alacritty`, or `gnome-terminal`
- **Not activating?** Check `systemctl --user status screensaver-daemon`
- **`tte` not found?** Ensure `~/.local/bin` is in your PATH
- **Not fullscreen?** Install `kitty`, `foot`, or `alacritty` for native fullscreen
- **Hyprland/Sway not working?** Install swayidle: `sudo pacman -S swayidle`
- **X11/KDE not working?** Install xprintidle: `sudo pacman -S xprintidle`
- **Check detected DE:** Run `journalctl --user -u screensaver-daemon | head -5`

## Uninstall

```bash
./uninstall.sh
```

This stops the service, removes the systemd unit, and optionally removes the project directory.

## Credits

- [TerminalTextEffects](https://github.com/ChrisBuilds/terminaltexteffects)

- Inspired by [Omarchy](https://github.com/basecamp/omarchy)



## License

MIT, feel free to use as you wish! See [LICENSE](LICENSE) for details.
