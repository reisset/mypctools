# scripts/bashrc_custom.sh

# 1. Source Aliases
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/aliases.sh" ]; then
    source "$SCRIPT_DIR/aliases.sh"
fi

# 2. Path additions (ensure ~/.local/bin is in PATH)
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

# 2.5 Default Editor (Micro if available)
if command -v micro &> /dev/null; then
    export EDITOR='micro'
    export VISUAL='micro'
fi

# 3. Starship Prompt
if command -v starship &> /dev/null; then
    eval "$(starship init bash)"
fi

# 4. FZF (Auto-enabled for Ctrl+T/Ctrl+R support)
# Keybindings can't be lazy-loaded since Ctrl+R is handled at readline level
# To disable: export MYBASH_DISABLE_FZF=1 before sourcing bashrc
if command -v fzf &> /dev/null && [ -z "$MYBASH_DISABLE_FZF" ]; then
    if fzf --bash &>/dev/null 2>&1; then
        eval "$(fzf --bash)"
    else
        source /usr/share/doc/fzf/examples/key-bindings.bash 2>/dev/null || true
    fi
fi

# 5. Yazi (Shell Wrapper to allow cwd change)
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

# 6. Auto-LS on cd
cd() {
    builtin cd "$@" || return
    if command -v eza &> /dev/null; then
        eza --icons
    else
        ls
    fi
}

# 7. Zoxide (Smart Directory Jumper - Lazy-loaded)
# Initializes on first use of 'z' command - saves ~60ms on startup
if command -v zoxide &> /dev/null; then
    z() {
        unset -f z zi  # Remove placeholder functions
        eval "$(zoxide init bash)"  # Initialize zoxide for real
        z "$@"  # Call the real z command with original arguments
    }
    zi() {
        unset -f z zi
        eval "$(zoxide init bash)"
        zi "$@"
    }
fi

# 8. Enhanced FZF Previews (bat + eza integration)
if command -v fzf &> /dev/null; then
    # Use bat for file previews and eza for directory previews
    # Only applies to CTRL-T (files) by default
    export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always --line-range :500 {} 2>/dev/null || eza --tree --level=2 --icons {} 2>/dev/null || cat {}'"
fi

# 9. Welcome Banner
if [[ $- == *i* ]] && [ -z "$MYBASH_WELCOME_SHOWN" ]; then
    # Try to display ASCII art banner
    # Use 'command cat' to bypass bat alias and show raw ASCII
    if [ -f "$HOME/.local/share/mybash/asciiart.txt" ]; then
        printf '%b\n' "$(command cat "$HOME/.local/share/mybash/asciiart.txt")"
    elif [ -f "$SCRIPT_DIR/../asciiart.txt" ]; then
        printf '%b\n' "$(command cat "$SCRIPT_DIR/../asciiart.txt")"
    fi
    echo ""  # Blank line for spacing
    echo -e "\033[0;90mType 'mybash -h' for help • 'mybash tools' for reference • 'mybash doctor' for diagnostics\033[0m"
    export MYBASH_WELCOME_SHOWN=1
fi
