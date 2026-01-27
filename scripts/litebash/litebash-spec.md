# LiteBash Project Specification

## Overview

**LiteBash** is a speed-focused, minimal bash environment for Linux power users. It prioritizes raw performance over features, using foot (the fastest Wayland terminal) and a stripped-down Starship prompt with git_status disabled.

The project is split into two independent components:
- **Shell Config** — Works everywhere (desktops, servers, headless systems, SSH sessions)
- **Terminal Config** — Wayland desktops only (foot terminal emulator)

---

## Project Structure

```
litebash/
├── README.md
├── LICENSE (MIT)
│
├── shell/
│   ├── install.sh
│   ├── uninstall.sh
│   ├── litebash.sh              # Main config (sourced by ~/.bashrc)
│   ├── aliases.sh
│   ├── functions.sh             # cd override, yazi wrapper, etc.
│   ├── prompt/
│   │   └── starship.toml        # Speed-optimized config
│   └── themes/
│       ├── catppuccin-mocha.sh  # DEFAULT
│       ├── tokyo-night.sh
│       └── hackthebox.sh
│
├── terminal/
│   ├── install.sh
│   ├── uninstall.sh
│   ├── foot.ini                 # Base foot config (imports theme)
│   └── themes/
│       ├── catppuccin-mocha.ini # DEFAULT
│       ├── tokyo-night.ini
│       └── hackthebox.ini
│
└── docs/
    └── TOOLS.md
```

---

## Core Tools to Install

The shell installer must install these tools (and ONLY these):

| Tool | Purpose | Package name variations |
|------|---------|------------------------|
| eza | Modern ls replacement | `eza` |
| bat | Modern cat with syntax highlighting | `bat` (arch), `batcat` (debian/ubuntu) |
| fzf | Fuzzy finder | `fzf` |
| ripgrep | Fast grep | `ripgrep` |
| zoxide | Smart cd | `zoxide` (GitHub install) |
| fd | Fast find | `fd` (arch), `fd-find` (debian/ubuntu) |
| btop | System monitor | `btop` |
| lazygit | Git TUI | `lazygit` (GitHub install) |
| micro | Terminal text editor | `micro` |
| tealdeer | tldr pages | `tealdeer` (GitHub install) |
| glow | Markdown renderer | `glow` (GitHub install) |
| dysk | Disk usage (better df) | `dysk` (GitHub install - precompiled binaries at https://github.com/Canop/dysk/releases) |
| gh | GitHub CLI | `gh` |
| starship | Prompt | `starship` (official installer script) |
| yazi | File manager | `yazi` (GitHub install) |

**Installation strategy:**
1. Try package manager first (pacman, apt, dnf)
2. Fall back to GitHub releases (precompiled binaries) for tools not in repos
3. Install binaries to `~/.local/bin`

**Distro package name mapping:**

| Tool | pacman | apt/debian | dnf/fedora |
|------|--------|------------|------------|
| bat | bat | bat | bat |
| fd | fd | fd-find | fd-find |
| ripgrep | ripgrep | ripgrep | ripgrep |
| eza | eza | eza | eza |
| btop | btop | btop | btop |
| micro | micro | micro | micro |
| gh | github-cli | gh | gh |
| fzf | fzf | fzf | fzf |

**Tools that typically need GitHub install:** zoxide, lazygit, tealdeer, glow, dysk, yazi, starship

---

## Sudo Requirement

**IMPORTANT:** Both install scripts require sudo. No fallback logic.

At the very start of each install script, prompt:

```bash
echo "This installer requires sudo privileges to function properly."
echo "Read the entire script if you do not trust the author."
echo ""
sudo -v || { echo "Sudo access required. Aborting."; exit 1; }
```

Same logic for uninstall scripts — require sudo or abort.

---

## Shell Config Specification

### `shell/litebash.sh`

This is the main file sourced by `~/.bashrc`. It should:

1. Set `PATH` to include `~/.local/bin`
2. Source `aliases.sh`
3. Source `functions.sh`
4. Source the selected theme file from `themes/`
5. Initialize zoxide: `eval "$(zoxide init bash)"`
6. Initialize fzf: `eval "$(fzf --bash)"` with fallback for older systems
7. Initialize starship: `eval "$(starship init bash)"`
8. Set `EDITOR=micro`

**Order matters for performance** — starship init should be last.

### `shell/aliases.sh`

```bash
# Core replacements - modern tools become the default
alias ls='eza -a --icons --group-directories-first'
alias ll='eza -al --icons --group-directories-first'
alias lt='eza -a --tree --level=2 --icons --group-directories-first'
alias cat='bat --paging=never'
alias grep='rg'
alias find='fd'
alias df='dysk'
alias top='btop'
alias vim='micro'
alias nano='micro'

# Git shortcuts
alias g='git'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias lg='lazygit'

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Utilities
alias c='clear'
alias h='history'
alias q='exit'
alias md='mkdir -p'
alias rd='rmdir'
alias please='sudo'

# Quick reference
alias tools='glow ~/.local/share/litebash/TOOLS.md 2>/dev/null || cat ~/.local/share/litebash/TOOLS.md'
```

### `shell/functions.sh`

```bash
# Auto-ls after cd (handles both arguments and no arguments)
cd() {
    if [ -n "$1" ]; then
        builtin cd "$@" && eza -a --icons --group-directories-first
    else
        builtin cd ~ && eza -a --icons --group-directories-first
    fi
}

# Yazi wrapper - changes directory on exit
y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}

# Quick directory creation and navigation
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Extract any archive
extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"   ;;
            *.tar.gz)    tar xzf "$1"   ;;
            *.tar.xz)    tar xJf "$1"   ;;
            *.bz2)       bunzip2 "$1"   ;;
            *.gz)        gunzip "$1"    ;;
            *.tar)       tar xf "$1"    ;;
            *.tbz2)      tar xjf "$1"   ;;
            *.tgz)       tar xzf "$1"   ;;
            *.zip)       unzip "$1"     ;;
            *.Z)         uncompress "$1";;
            *.7z)        7z x "$1"      ;;
            *.rar)       unrar x "$1"   ;;
            *)           echo "'$1' cannot be extracted" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}
```

### `shell/prompt/starship.toml`

**Design goals:**
- Minimal modules for speed
- `git_status` DISABLED (biggest performance gain — saves 200-1000ms in large repos)
- `git_branch` enabled (fast — just reads `.git/HEAD` file)
- No language version scanning
- No newline padding
- Clean, minimal aesthetic

```toml
# LiteBash Starship Config - Speed Optimized
# git_status is DISABLED for performance

palette = "catppuccin_mocha"

format = """$directory$git_branch$python$character"""

add_newline = false

[character]
success_symbol = "[❯](green)"
error_symbol = "[❯](red)"

[directory]
truncation_length = 3
truncate_to_repo = true
style = "bold lavender"
read_only = " 󰌾"

[git_branch]
format = "[$symbol$branch]($style) "
symbol = " "
style = "bold mauve"

[git_status]
disabled = true

[python]
format = '[( $virtualenv)]($style) '
style = "yellow"
detect_extensions = []
detect_files = []

[nodejs]
disabled = true

[package]
disabled = true

[cmd_duration]
min_time = 2000
format = "[$duration]($style) "
style = "bold peach"

# Catppuccin Mocha Palette
[palettes.catppuccin_mocha]
rosewater = "#f5e0dc"
flamingo = "#f2cdcd"
pink = "#f5c2e7"
mauve = "#cba6f7"
red = "#f38ba8"
maroon = "#eba0ac"
peach = "#fab387"
yellow = "#f9e2af"
green = "#a6e3a1"
teal = "#94e2d5"
sky = "#89dceb"
sapphire = "#74c7ec"
blue = "#89b4fa"
lavender = "#b4befe"
text = "#cdd6f4"
subtext1 = "#bac2de"
subtext0 = "#a6adc8"
overlay2 = "#9399b2"
overlay1 = "#7f849c"
overlay0 = "#6c7086"
surface2 = "#585b70"
surface1 = "#45475a"
surface0 = "#313244"
base = "#1e1e2e"
mantle = "#181825"
crust = "#11111b"
```

**Note:** The palette definition is for Catppuccin Mocha. When user selects a different theme during install, the starship.toml should be modified to use the appropriate palette (or the palette section should be swapped).

---

## Theme Files Specification

### Shell Themes (`shell/themes/*.sh`)

Each theme exports environment variables for CLI tools.

**Required exports:**
- `FZF_DEFAULT_OPTS` — Full color scheme for fzf
- `BAT_THEME` — Theme name for bat
- `LITEBASH_THEME` — Theme identifier

#### `catppuccin-mocha.sh` (DEFAULT)

```bash
#!/usr/bin/env bash
# LiteBash Theme: Catppuccin Mocha

export LITEBASH_THEME="catppuccin-mocha"

# FZF colors
export FZF_DEFAULT_OPTS="
    --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8
    --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc
    --color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8
    --color=selected-bg:#45475a
    --multi"

# Bat theme
export BAT_THEME="Catppuccin Mocha"
```

#### `tokyo-night.sh`

```bash
#!/usr/bin/env bash
# LiteBash Theme: Tokyo Night

export LITEBASH_THEME="tokyo-night"

# FZF colors (Tokyo Night palette)
export FZF_DEFAULT_OPTS="
    --color=bg+:#292e42,bg:#1a1b26,spinner:#bb9af7,hl:#f7768e
    --color=fg:#c0caf5,header:#f7768e,info:#7aa2f7,pointer:#bb9af7
    --color=marker:#9ece6a,fg+:#c0caf5,prompt:#7aa2f7,hl+:#f7768e
    --color=selected-bg:#33467c
    --multi"

# Bat theme
export BAT_THEME="TwoDark"
```

#### `hackthebox.sh`

```bash
#!/usr/bin/env bash
# LiteBash Theme: HackTheBox (Green Hacker Aesthetic)

export LITEBASH_THEME="hackthebox"

# FZF colors (HTB green/black palette)
export FZF_DEFAULT_OPTS="
    --color=bg+:#1a2332,bg:#141d2b,spinner:#9fef00,hl:#9fef00
    --color=fg:#a4b1cd,header:#9fef00,info:#ffaf00,pointer:#9fef00
    --color=marker:#9fef00,fg+:#ffffff,prompt:#9fef00,hl+:#9fef00
    --color=selected-bg:#1a2332
    --multi"

# Bat theme (closest match)
export BAT_THEME="base16"
```

### Terminal Themes (`terminal/themes/*.ini`)

foot uses INI format. Each theme file contains only the `[colors]` section.

#### `catppuccin-mocha.ini` (DEFAULT)

```ini
# LiteBash foot theme: Catppuccin Mocha

[colors]
background=1e1e2e
foreground=cdd6f4

regular0=45475a
regular1=f38ba8
regular2=a6e3a1
regular3=f9e2af
regular4=89b4fa
regular5=f5c2e7
regular6=94e2d5
regular7=bac2de

bright0=585b70
bright1=f38ba8
bright2=a6e3a1
bright3=f9e2af
bright4=89b4fa
bright5=f5c2e7
bright6=94e2d5
bright7=a6adc8
```

#### `tokyo-night.ini`

```ini
# LiteBash foot theme: Tokyo Night

[colors]
background=1a1b26
foreground=c0caf5

regular0=15161e
regular1=f7768e
regular2=9ece6a
regular3=e0af68
regular4=7aa2f7
regular5=bb9af7
regular6=7dcfff
regular7=a9b1d6

bright0=414868
bright1=f7768e
bright2=9ece6a
bright3=e0af68
bright4=7aa2f7
bright5=bb9af7
bright6=7dcfff
bright7=c0caf5
```

#### `hackthebox.ini`

```ini
# LiteBash foot theme: HackTheBox

[colors]
background=141d2b
foreground=a4b1cd

regular0=141d2b
regular1=ff3e3e
regular2=9fef00
regular3=ffaf00
regular4=2b6cb0
regular5=9f7aea
regular6=0bc5ea
regular7=a4b1cd

bright0=1a2332
bright1=ff3e3e
bright2=9fef00
bright3=ffaf00
bright4=63b3ed
bright5=b794f4
bright6=0bc5ea
bright7=ffffff
```

---

## Terminal Config Specification

### `terminal/foot.ini`

Base configuration (theme colors are appended during install):

```ini
# LiteBash foot configuration

[main]
font=IosevkaTerm Nerd Font:size=14
pad=10x10
dpi-aware=yes

[bell]
urgent=no
notify=no

[scrollback]
lines=10000

[url]
launch=xdg-open ${url}

[cursor]
style=beam
blink=yes

[mouse]
hide-when-typing=yes
```

**Font name variations to check:** `IosevkaTerm Nerd Font`, `IosevkaTerm NF`, `Iosevka Term Nerd Font`, `Iosevka Nerd Font`. The installer should detect which variant is installed and use the correct name.

---

## Installer Specifications

### `shell/install.sh`

**Flow:**

1. Print sudo requirement notice and request sudo
2. Detect package manager (pacman, apt, dnf, zypper)
3. Prompt for theme selection:
   ```
   Select theme:
   1) Catppuccin Mocha (default)
   2) Tokyo Night
   3) HackTheBox
   [1/2/3]:
   ```
4. Install dependencies (curl, unzip, tar, git, fontconfig)
5. Install all core tools:
   - Package manager first
   - GitHub releases fallback for tools not in repos
6. Create `~/.local/bin` if needed, ensure it's in PATH
7. Create `~/.config/starship.toml` (copy from repo, modify palette if non-default theme)
8. Create `~/.local/share/litebash/` directory
9. Copy shell configs to `~/.local/share/litebash/`
10. Copy selected theme to `~/.local/share/litebash/theme.sh`
11. Copy `TOOLS.md` to `~/.local/share/litebash/`
12. Add source line to `~/.bashrc` if not already present:
    ```bash
    # LiteBash
    [ -f ~/.local/share/litebash/litebash.sh ] && source ~/.local/share/litebash/litebash.sh
    ```
13. Print success message: "Installation complete! Restart your shell or run: source ~/.bashrc"

**GitHub install helper function:**

```bash
install_from_github() {
    local repo=$1      # e.g., "ajeetdsouza/zoxide"
    local binary=$2    # e.g., "zoxide"
    local pattern=$3   # e.g., "x86_64.*linux.*musl"
    
    # Fetch latest release URL matching pattern
    # Download to /tmp
    # Extract if archive
    # Move binary to ~/.local/bin
    # chmod +x
}
```

**Architecture detection:**
```bash
ARCH=$(uname -m)
# x86_64, aarch64, armv7l, etc.
```

### `terminal/install.sh`

**Flow:**

1. Print sudo requirement notice and request sudo
2. Check if running on Wayland:
   ```bash
   if [ -z "$WAYLAND_DISPLAY" ]; then
       echo "Error: Wayland not detected. foot is Wayland-only."
       echo "If you're on X11, foot will not work."
       exit 1
   fi
   ```
3. Detect package manager
4. Install foot via package manager
5. Install Iosevka Nerd Font:
   - Download `IosevkaTerm.zip` from https://github.com/ryanoasis/nerd-fonts/releases/latest
   - Extract to `~/.local/share/fonts/`
   - Run `fc-cache -fv`
6. Prompt for theme selection (same as shell installer)
7. Create `~/.config/foot/` directory
8. Create `foot.ini` by combining base config + selected theme's color section
9. Print success message

### `shell/uninstall.sh`

**Flow:**

1. Request sudo or abort
2. Remove source line from `~/.bashrc`
3. Remove `~/.local/share/litebash/` directory
4. Remove `~/.config/starship.toml`
5. Prompt: "Remove installed CLI tools? [y/N]" — if yes, attempt to remove packages
6. Print: "Shell config removed. Tools left in place unless you chose to remove them."

### `terminal/uninstall.sh`

**Flow:**

1. Request sudo or abort
2. Remove `~/.config/foot/` directory (or just foot.ini if user has other foot configs)
3. Do NOT remove fonts
4. Print: "foot config removed. Font left in place."

---

## TOOLS.md Content

```markdown
# LiteBash Quick Reference

## Navigation
- `z <partial-path>` — Smart jump (zoxide)
- `y` or `yazi` — File manager (changes dir on exit)
- `cd` — Auto-lists directory contents

## File Operations
- `ls` / `ll` / `lt` — List files (eza)
- `cat <file>` — View with syntax highlighting (bat)
- `find <name>` — Fast file search (fd)
- `grep <pattern>` — Fast search (ripgrep)

## Git
- `lg` — LazyGit TUI
- `gs` — git status
- `ga` — git add
- `gc` — git commit
- `gp` — git push
- `gl` — git pull
- `gh` — GitHub CLI

## System
- `top` / `btop` — System monitor
- `df` / `dysk` — Disk usage

## Editing
- `micro <file>` — Text editor
- `vim` / `nano` — Also opens micro

## Utilities
- `tldr <cmd>` — Quick command help
- `glow <file.md>` — Render markdown
- `extract <archive>` — Extract any archive format
- `mkcd <dir>` — Create and enter directory
- `tools` — Show this reference

## FZF Shortcuts
- `Ctrl+R` — Search command history
- `Ctrl+T` — Search files
- `Alt+C` — Search and cd into directory
```

---

## README.md Content Outline

1. **Hero section**
   - Project name: LiteBash
   - Tagline: "Speed-focused bash environment for Linux power users"
   - Screenshot of foot + starship prompt with Catppuccin theme

2. **Philosophy**
   - Speed over features
   - Split architecture: shell vs terminal
   - Modern tools as defaults (not supplements)

3. **What's included**
   - Tool list with one-line descriptions
   - Theme options

4. **Installation**
   ```bash
   # Clone
   git clone https://github.com/YOUR_USERNAME/litebash.git
   cd litebash

   # Shell config (works everywhere)
   cd shell && ./install.sh

   # Terminal config (Wayland desktops only)
   cd ../terminal && ./install.sh
   ```

5. **Theme switching**
   - Re-run installer, or
   - Manually edit `~/.local/share/litebash/theme.sh` and `~/.config/foot/foot.ini`

6. **Customization**
   - Config locations
   - How to add aliases
   - How to modify prompt

7. **Uninstallation**
   ```bash
   cd shell && ./uninstall.sh
   cd ../terminal && ./uninstall.sh
   ```

8. **Credits/License** — MIT

---

## Implementation Notes

1. **Idempotent installs** — Running install.sh twice should not duplicate bashrc lines or break anything. Check before adding.

2. **No hardcoded paths** — Use `$HOME`, detect paths dynamically.

3. **Respect XDG** — Configs in `~/.config/`, data in `~/.local/share/`.

4. **GitHub API rate limits** — When fetching releases, handle 403 errors gracefully. Suggest manual install if rate limited.

5. **Fail gracefully** — If a single tool fails to install, warn but continue. Don't abort the whole install.

6. **Symlinks vs copies** — Copy files to `~/.local/share/litebash/` so the user can delete the git repo after install if they want. The install is self-contained.

7. **batcat symlink** — On Debian/Ubuntu, bat is installed as `batcat`. Create symlink: `ln -sf /usr/bin/batcat ~/.local/bin/bat`

8. **fd-find symlink** — On Debian/Ubuntu, fd is installed as `fdfind`. Create symlink: `ln -sf /usr/bin/fdfind ~/.local/bin/fd`
