#!/usr/bin/env zsh
# LiteZsh Completion Configuration

# Initialize completion system
autoload -Uz compinit
compinit -d "$HOME/.cache/zsh/zcompdump-$ZSH_VERSION"

# Menu-style completion (navigate with arrows)
zstyle ':completion:*' menu select

# Case-insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Colorize completions using default LS_COLORS
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Group completions by category
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'

# Faster completion initialization (only check once per day)
# Create cache directory if needed
[[ -d "$HOME/.cache/zsh" ]] || mkdir -p "$HOME/.cache/zsh"
