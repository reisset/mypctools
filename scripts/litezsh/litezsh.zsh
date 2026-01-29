#!/usr/bin/env zsh
# LiteZsh - Speed-focused zsh environment

# Ensure ~/.local/bin is in PATH
[[ ":$PATH:" != *":$HOME/.local/bin:"* ]] && export PATH="$HOME/.local/bin:$PATH"

# Config directory
LITEZSH_DIR="$HOME/.local/share/litezsh"

# Source config files
[[ -f "$LITEZSH_DIR/aliases.sh" ]] && source "$LITEZSH_DIR/aliases.sh"
[[ -f "$LITEZSH_DIR/functions.zsh" ]] && source "$LITEZSH_DIR/functions.zsh"
[[ -f "$LITEZSH_DIR/completions.zsh" ]] && source "$LITEZSH_DIR/completions.zsh"

# Quick reference (points to local copy)
alias tools='glow "$LITEZSH_DIR/TOOLS.md" 2>/dev/null || cat "$LITEZSH_DIR/TOOLS.md"'

# FZF defaults
export FZF_DEFAULT_OPTS="--multi"

# Initialize tools (same as litebash)
command -v zoxide &>/dev/null && eval "$(zoxide init zsh)" && {
    # Override zoxide's cd to enable auto-ls
    __zoxide_cd() {
        \builtin cd -- "$@" && eza -lh --group-directories-first --icons=auto
    }
}
command -v fzf &>/dev/null && source <(fzf --zsh 2>/dev/null) || {
    # Fallback for older fzf versions (Arch path, then Debian path)
    if [[ -f /usr/share/fzf/key-bindings.zsh ]]; then
        source /usr/share/fzf/key-bindings.zsh
    elif [[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]]; then
        source /usr/share/doc/fzf/examples/key-bindings.zsh
    fi
    if [[ -f /usr/share/fzf/completion.zsh ]]; then
        source /usr/share/fzf/completion.zsh
    elif [[ -f /usr/share/doc/fzf/examples/completion.zsh ]]; then
        source /usr/share/doc/fzf/examples/completion.zsh
    fi
}
command -v starship &>/dev/null && eval "$(starship init zsh)"

# Set default editor
export EDITOR=micro

# History configuration
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS      # Don't record duplicates
setopt HIST_IGNORE_SPACE     # Don't record commands starting with space
setopt SHARE_HISTORY         # Share history between sessions
setopt APPEND_HISTORY        # Append instead of overwrite

# Up-arrow history search (type partial command, press up to search)
autoload -U up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search   # Up arrow
bindkey "^[[B" down-line-or-beginning-search # Down arrow

# Load plugins (order matters - syntax-highlighting must be last)
[[ -f "$LITEZSH_DIR/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] && \
    source "$LITEZSH_DIR/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
[[ -f "$LITEZSH_DIR/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] && \
    source "$LITEZSH_DIR/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
