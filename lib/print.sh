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

# Prompt for sudo and keep credentials alive in background
# Call at the start of scripts that need sustained sudo access
init_sudo() {
    echo "This installer requires sudo privileges to function properly."
    echo "Read the entire script if you do not trust the author."
    echo ""
    sudo -v || { print_error "Sudo access required. Aborting."; exit 1; }
    while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
}
