#!/usr/bin/env zsh
# LiteZsh Aliases

# Core replacements - modern tools become the default
alias ls='eza -a --icons --group-directories-first'
alias ll='eza -al --icons --group-directories-first'
alias lt='eza -a --tree --level=2 --icons --group-directories-first'
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
alias tools='glow ~/.local/share/litezsh/TOOLS.md 2>/dev/null || cat ~/.local/share/litezsh/TOOLS.md'
