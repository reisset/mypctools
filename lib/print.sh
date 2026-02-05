#!/usr/bin/env bash
# Shared print functions — zero dependencies (pure ANSI, no gum)
# Source this from any script that needs colored output

[[ -n "$_PRINT_SH_LOADED" ]] && return 0
_PRINT_SH_LOADED=1

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[*]${NC} $1"; }
print_success() { echo -e "${GREEN}[✓]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1"; }

# Header - simple ANSI version
print_header() { echo -e "\n${BLUE}━━━ $1 ━━━${NC}\n"; }

# Info - alias for status
print_info() { print_status "$1"; }

# Check if command exists
command_exists() { command -v "$1" &>/dev/null; }

# Prompt for sudo (wrapper)
ensure_sudo() {
    sudo -v || { print_error "Sudo access required."; return 1; }
}

# Simple menu selection (replaces themed_choose)
# Usage: result=$(simple_choose "Prompt:" "opt1" "opt2" "opt3")
simple_choose() {
    local prompt="$1"
    shift
    local options=("$@")
    local i=1

    echo -e "${BLUE}$prompt${NC}" >&2
    for opt in "${options[@]}"; do
        echo "  $i) $opt" >&2
        ((i++))
    done

    local choice
    while true; do
        read -rp "Enter number: " choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#options[@]} )); then
            echo "${options[$((choice-1))]}"
            return 0
        fi
        echo "Invalid selection. Enter 1-${#options[@]}." >&2
    done
}

# Prompt for sudo and keep credentials alive in background
# Call at the start of scripts that need sustained sudo access
init_sudo() {
    echo "This installer requires sudo privileges to function properly."
    echo "Read the entire script if you do not trust the author."
    echo ""
    sudo -v || { print_error "Sudo access required. Aborting."; exit 1; }
    while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
}
