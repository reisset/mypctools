# scripts/aliases.sh

# Eza (modern ls)
if command -v eza &> /dev/null; then
  alias ls='eza --icons'
  alias ll='eza -al --icons --group-directories-first'
  alias la='eza -a --icons --group-directories-first'
  alias lt='eza --tree --level=2 --icons'
else
  alias ll='ls -alF'
  alias la='ls -A'
  alias l='ls -CF'
fi

# Ripgrep (use 'rg' directly - grep alias moved to POWER MODE below)

# Bat (modern cat)
if command -v batcat &> /dev/null; then
  alias cat='batcat'
elif command -v bat &> /dev/null; then
  alias cat='bat'
fi

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'

# Git shortcuts
alias g='git'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'

# Modern CLI Tools (Learning-First)
# Navigation & Search
# Note: z and zi are lazy-loaded in bashrc_custom.sh
if command -v fdfind &> /dev/null; then
    alias fdf='fdfind'
elif command -v fd &> /dev/null; then
    alias fdf='fd'
fi

# System Monitoring
if command -v btop &> /dev/null; then
    alias top='btop'
fi
if command -v procs &> /dev/null; then
    alias px='procs'
fi

# Development
if command -v lazygit &> /dev/null; then
    alias lg='lazygit'
fi
if command -v hyperfine &> /dev/null; then
    alias benchmark='hyperfine'
fi
if command -v tokei &> /dev/null; then
    alias cloc='tokei'
fi

# Micro Editor
if command -v micro &> /dev/null; then
    alias m='micro'
    alias edit='micro'
fi

# Kitty Kittens (Terminal Eye Candy - only if running in Kitty)
if [ "$TERM" = "xterm-kitty" ]; then
    alias icat='kitten icat'           # Display images in terminal
    alias kdiff='kitten diff'          # Syntax-highlighted diff viewer
fi

# Quick Reference (mybash command is installed to ~/.local/bin/)
alias tools='cat ~/.local/share/mybash/TOOLS.md 2>/dev/null || cat ~/mybash/docs/TOOLS.md'

# ==============================================================================
# OPTIONAL: POWER MODE (Uncomment to replace standard commands)
# WARNING: This breaks muscle memory for vanilla systems.
# ==============================================================================
# alias cd='z'
# alias du='dust'
# alias find='fd'
# alias ps='procs'
# alias grep='rg'
# alias nano='micro'
# ==============================================================================
