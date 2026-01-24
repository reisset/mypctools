# MyBash V2

An opinionated, high-performance Bash setup for Ubuntu/Debian, Arch-based distros (CachyOS, EndeavourOS, Manjaro), and Pop!_OS 24.04 (COSMIC desktop). I built this to help me learn Linux without getting stuck in the past—it blends modern tools for speed with standard commands for muscle memory. **This project is inspired by @ChrisTitusTech Mybash**

## Preview
<img width="2943" height="1841" alt="Screenshot from 2025-12-23 15-16-16" src="https://github.com/user-attachments/assets/210577bd-1589-49cc-ad30-22dbae6a0f02" />


## The Goods

- **Starship Prompt:** Fast, informative, and git-aware.
- **Modern Toolset:** Includes `zoxide` (better cd), `eza` (better ls), `bat`, `fzf`, `lazygit`, `yazi` (modern TUI file browser), and `micro` (intuitive editor).
- **Muscle Memory Safe:** Standard commands (cd, grep) still work, so you won't get lost.
- **Look & Feel:** Tokyo Night theme, syntax-highlighted diffs, and smart aliases.
- **Kitty Terminal:** [Optional] config with GPU acceleration, Nerd Fonts, and kitten shortcuts (image viewer, URL hints, theme switcher).

<img width="2944" height="1836" alt="Screenshot from 2025-12-19 15-28-56" src="https://github.com/user-attachments/assets/7d2685b9-5fc8-483c-9545-25b34e79e350" />

## Quick Start
Don't just run random scripts from the internet. Read the code first.

1. **Clone & Inspect:**
    *(You may need to install git first: `sudo apt install git` on Debian/Ubuntu or `sudo pacman -S git` on Arch)*
    ```bash
    git clone https://github.com/reisset/mybash.git
    cd mybash
    cat install.sh  # Review before running
    ```

2. **Install:**
    ```bash
    ./install.sh           # Full desktop install
    ./install.sh --server  # Headless/server install (skips fonts, Kitty, lazygit, nvtop)
    ```

3. **Finish Up:**
    Open your terminal settings and select **JetBrainsMono Nerd Font** (the script installs this for you) to ensure icons render correctly.

### Security

I don't like piping curl straight to bash. This installer:
- Validates download URLs.
- Checks GPG keys for packages.
- Only asks for sudo when absolutely necessary.

For detailed security information, see [SECURITY.md](SECURITY.md).

## Tweaking configs

- **Aliases:** `scripts/aliases.sh`.
- **Bash Logic:** `scripts/bashrc_custom.sh`.
- **Prompt:** `configs/starship_text.toml`.
- **Kitty:** `configs/kitty.conf` (symlinked to `~/.config/kitty/kitty.conf`).
- **ASCII art:** `asciiart.txt` 

## MyBash Commands (V2.2+)

MyBash includes a unified CLI for help and diagnostics:

```bash
mybash           # Quick status
mybash -h        # Show help with subcommands and alias reference
mybash tools     # Browse available modern tools (uses glow)
mybash doctor    # Run health checks and diagnostics
mybash version   # Show version
./uninstall.sh   # Safely remove MyBash
```

## License

MIT License - see [LICENSE](LICENSE) for details.
