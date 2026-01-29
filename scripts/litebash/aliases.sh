#!/usr/bin/env bash
# LiteBash Aliases

# Core replacements - modern tools become the default
alias ls='eza -lh --group-directories-first --icons=auto'
alias ll='eza -alh --group-directories-first --icons=auto'
alias lt='eza --tree --level=2 --long --icons --git'
alias cat='bat --paging=never'
alias grep='rg'
alias find='fd'
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
