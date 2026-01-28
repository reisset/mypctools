#!/usr/bin/env zsh
# LiteZsh Functions

# Auto-ls after cd
cd() {
    builtin cd "$@" && eza -a --icons --group-directories-first
}

# Yazi wrapper - changes directory on exit
y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
    yazi "$@" --cwd-file="$tmp"
    if [[ -r "$tmp" ]]; then
        local cwd="$(<$tmp)"  # zsh syntax for reading file
        [[ -n "$cwd" && "$cwd" != "$PWD" ]] && builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}

# Quick directory creation and navigation
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Extract any archive (identical to bash version)
extract() {
    if [[ -f "$1" ]]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"   ;;
            *.tar.gz)    tar xzf "$1"   ;;
            *.tar.xz)    tar xJf "$1"   ;;
            *.bz2)       bunzip2 "$1"   ;;
            *.gz)        gunzip "$1"    ;;
            *.tar)       tar xf "$1"    ;;
            *.tbz2)      tar xjf "$1"   ;;
            *.tgz)       tar xzf "$1"   ;;
            *.zip)       unzip "$1"     ;;
            *.Z)         uncompress "$1";;
            *.7z)        7z x "$1"      ;;
            *.rar)       unrar x "$1"   ;;
            *)           echo "'$1' cannot be extracted" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}
