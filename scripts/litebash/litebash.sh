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
command -v zoxide &>/dev/null && eval "$(zoxide init bash)"
command -v fzf &>/dev/null && eval "$(fzf --bash 2>/dev/null)" || eval "$(fzf --completion --key-bindings 2>/dev/null)"
command -v starship &>/dev/null && eval "$(starship init bash)"

# Set default editor
export EDITOR=micro
