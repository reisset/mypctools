#!/usr/bin/env bash
# LiteBash - Speed-focused bash environment
# https://github.com/nickfox-taterli/litebash

# Ensure ~/.local/bin is in PATH
[[ ":$PATH:" != *":$HOME/.local/bin:"* ]] && export PATH="$HOME/.local/bin:$PATH"

# Source config files
LITEBASH_DIR="$HOME/.local/share/litebash"
[ -f "$LITEBASH_DIR/aliases.sh" ] && source "$LITEBASH_DIR/aliases.sh"
[ -f "$LITEBASH_DIR/functions.sh" ] && source "$LITEBASH_DIR/functions.sh"

# Quick reference (points to local copy)
alias tools='glow "$LITEBASH_DIR/TOOLS.md" 2>/dev/null || cat "$LITEBASH_DIR/TOOLS.md"'

# FZF defaults
export FZF_DEFAULT_OPTS="--multi"

# Initialize tools
command -v zoxide &>/dev/null && eval "$(zoxide init bash)" && {
    # Override zoxide's cd to enable auto-ls
    __zoxide_cd() {
        \builtin cd -- "$@" && eza -lh --group-directories-first --icons=auto
    }
}
if command -v fzf &>/dev/null; then
    if _fzf_init=$(fzf --bash 2>/dev/null) && [[ -n "$_fzf_init" ]]; then
        eval "$_fzf_init"
    else
        eval "$(fzf --completion --key-bindings 2>/dev/null)"
    fi
    unset _fzf_init
fi
command -v starship &>/dev/null && eval "$(starship init bash)"

# Set default editor
export EDITOR=micro
