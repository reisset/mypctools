# mypctools - Project Requirements Document

## Overview

A personal TUI (Terminal User Interface) application that consolidates all of my GitHub scripts, dotfiles, and provides an easy app installation system. Built with **Gum** (by Charm) for the terminal UI, written entirely in Bash.

Think of it as a personal version of Chris Titus's Linutil — one launcher to rule all my tools.

## Goals

- Single `git clone` to bootstrap any new Linux system
- Consolidate existing GitHub repos into one organized structure
- Easy app installation (apt preferred, flatpak fallback, must also include arch-based systems installs via pacman)
- Clean, navigable TUI menu system
- Modular design so new scripts/apps can be added easily
- Cross-platform reference (PowerShell scripts stored for Windows use)

## Tech Stack

- **Shell**: Bash (POSIX-compatible where reasonable)
- **TUI Framework**: Gum (https://github.com/charmbracelet/gum)
- **Package Management**: apt (primary) // pacman (primary if arch-based distro), flatpak (fallback), manual installs where needed
- **Target OS**: Ubuntu/Pop!_OS (Debian-based), but keep arch-based distros discoverable/ portable where possible

## Directory Structure

```
mypctools/
├── launcher.sh              # Main entry point - the TUI menu
├── install.sh               # Bootstrap script (installs gum, sets up PATH)
├── uninstall.sh             # Clean removal script
├── lib/
│   ├── helpers.sh           # Shared functions (colors, prompts, logging)
│   ├── package-manager.sh   # apt/flatpak detection and install logic
│   └── distro-detect.sh     # Detect Ubuntu/Pop/Debian/etc
├── apps/
│   ├── browsers.sh          # Brave, Firefox, Zen, etc.
│   ├── gaming.sh            # Steam, Lutris, ProtonUp-Qt, etc.
│   ├── media.sh             # Spotify, VLC, MPV, etc.
│   ├── dev-tools.sh         # LazyDocker, Caligula, Docker, etc.
│   └── cli-utils.sh         # fzf, bat, eza, ripgrep, btop, etc.
├── scripts/
│   ├── bash/                # Content from: github.com/reisset/mybash
│   │   ├── install.sh
│   │   ├── uninstall.sh
│   │   ├── .bashrc
│   │   └── kitty/
│   ├── screensavers/        # Content from: github.com/reisset/myscreensavers
│   │   ├── install.sh
│   │   └── ...
│   └── claude/              # Content from: ~/home/nick/claudesetup (private)
│       └── ...              # User will add manually
├── windows/
│   └── powershell/          # Content from: github.com/reisset/mypowershell
│       └── ...              # Reference only - not executable from TUI
├── configs/                 # Dotfiles and app configs for symlinking
└── README.md
```

## Core Components

### 1. launcher.sh (Main Entry Point)

The main TUI menu using Gum. Should present a clean menu with categories:

```
┌─────────────────────────────────┐
│        mypctools v0.1           │
├─────────────────────────────────┤
│  > Install Apps                 │
│    My Scripts                   │
│    System Setup                 │
│    Settings                     │
│    Exit                         │
└─────────────────────────────────┘
```

**Menu Structure:**
- **Install Apps** → submenu: Browsers, Gaming, Media, Dev Tools, CLI Utils
- **My Scripts** → submenu: Bash Setup, Screensavers, Claude Setup
- **System Setup** → Future: system tweaks, configs
- **Settings** → Future: preferences, update checker
- **Exit**

### 2. install.sh (Bootstrap)

What it should do:
1. Check if gum is installed, if not install it
2. Optionally add mypctools to PATH (symlink launcher.sh to ~/.local/bin/mypctools)
3. Make all scripts executable
4. Display success message with how to run

```bash
# User runs:
git clone https://github.com/reisset/mypctools.git
cd mypctools
./install.sh

# Then can run from anywhere:
mypctools
```

### 3. lib/helpers.sh (Shared Functions)

Common functions all scripts can source:

```bash
# Colors and formatting
print_header()
print_success()
print_error()
print_warning()

# Gum wrappers
confirm_action()      # Yes/no prompt
choose_option()       # Selection menu
show_spinner()        # Loading indicator

# Logging
log_info()
log_error()
```

### 4. lib/package-manager.sh (Install Logic)

**Core principle: apt/pacman first, flatpak fallback**

```bash
# Function signature
install_package "package_name" "apt_package" "pacman_package" "flatpak_package" "fallback_script"

# Example usage in apps/browsers.sh:
install_package "Brave Browser" "brave-browser" "com.brave.Browser" "install_brave_manual"
```

Logic:
1. Try apt install (or pacman if arch-based distro), if apt_package provided
2. If apt/pacman fails or unavailable, try flatpak if flatpak_package provided
3. If both fail, run fallback_script if provided
4. Report success/failure

### 5. App Installation Scripts (apps/*.sh)

Each file handles one category. When selected from TUI, shows a checklist of apps in that category.

**Example: apps/cli-utils.sh**
```
Select CLI utilities to install:
[x] fzf - Fuzzy finder
[x] bat - Better cat
[ ] eza - Better ls
[x] ripgrep - Better grep
[ ] btop - Better htop
[x] lazydocker - Docker TUI
[ ] caligula - ISO burner
```

User selects multiple, then installs all selected.

**Initial App Lists:**

**browsers.sh:**
- Brave Browser
- Firefox (if not present)
- Zen Browser

**gaming.sh:**
- Steam
- Lutris
- ProtonUp-Qt
- Heroic Games Launcher

**media.sh:**
- Spotify
- VLC
- MPV

**dev-tools.sh:**
- Docker / Docker compose
- LazyDocker
- VSCode / Cursor
- LM Studio (AppImage)
- Ollama
- .NET Framework
- Python:latest

**cli-utils.sh:**
- fzf
- bat
- eza
- ripgrep
- fd-find
- btop
- tldr
- zoxide
- caligula
- gum (should already be installed)

### 6. My Scripts Integration (scripts/*)

Each subfolder contains the consolidated content from my existing repos. The TUI provides menu options to:
- **Run install script** for that category
- **Run uninstall script** if available
- **View info/README** about what it does

**scripts/bash/** (from mybash):
- Installs custom .bashrc
- Installs kitty terminal config
- Sets up starship prompt if desired

**scripts/screensavers/** (from myscreensavers):
- Installs cmatrix, pipes.sh, cbonsai, etc.
- Configures screensaver shortcuts

**scripts/claude/** (from claudesetup - private):
- Located on local installation (Private repo)
- Claude Code setup, Skills, prompt, etc.

### 7. Windows PowerShell Reference (windows/powershell/)

Not executable from the TUI, but stored for reference and portability. Menu option should:
- Display a note that these are Windows scripts
- Offer to open the folder or show the README (provide github link to repo)

## Gum Usage Examples

For Claude Code reference, here's how Gum works:

```bash
# Simple menu selection
choice=$(gum choose "Option 1" "Option 2" "Option 3")

# Multi-select with checkboxes
choices=$(gum choose --no-limit "fzf" "bat" "eza" "ripgrep")

# Yes/No confirmation
gum confirm "Install Brave Browser?" && install_brave

# Styled header
gum style --border normal --padding "1 2" --border-foreground 212 "mypctools"

# Input prompt
name=$(gum input --placeholder "Enter name")

# Spinner while running command
gum spin --spinner dot --title "Installing..." -- apt install -y package

# Filter/search through options
choice=$(echo -e "option1\noption2\noption3" | gum filter)
```

## Error Handling

- Always check if running as root when needed (some installs need sudo)
- Graceful fallbacks when packages unavailable
- Clear error messages with suggested fixes
- Don't exit entire app on single failure — return to menu

## Future Enhancements (Not for initial build)

- Update checker (git pull from menu)
- Backup/restore configs
- System info display
- General TUI polish/ improvements
- Theme selection for the TUI itself
- Fedora package manager support

## Notes for Claude Code

1. Start by creating the directory structure and empty files
2. Build lib/helpers.sh and lib/package-manager.sh first (foundation)
3. Build launcher.sh with basic menu navigation
4. Add one complete app category (cli-utils.sh) as a working example
5. Add scripts/bash/ integration as example of existing repo consolidation
6. Keep it simple and modular — easy to extend later

The user (Nick) is a vibe-coder who works best with AI assistance. Keep code readable with only important comments. Prefer simple bash over clever one-liners.

## Repository Migration Plan

After initial build works:
1. Archive old repos (make read-only, update README to point to mypctools)
2. Copy content from mybash, myscreensavers into scripts/
3. User manually adds claudesetup content
4. Copy mypowershell into windows/powershell/
5. Test all install/uninstall scripts work from new locations
