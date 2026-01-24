#!/usr/bin/env bash
# mypctools/lib/helpers.sh
# Shared helper functions for mypctools
# v0.1.0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Print functions
print_header() {
    echo -e "${MAGENTA}==>${NC} ${CYAN}$1${NC}"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1" >&2
}

print_warning() {
    echo -e "${YELLOW}!${NC} $1"
}

print_info() {
    echo -e "${BLUE}→${NC} $1"
}

# Gum wrappers
confirm_action() {
    local prompt="${1:-Are you sure?}"
    gum confirm "$prompt"
}

choose_option() {
    local header="$1"
    shift
    gum choose --header "$header" "$@"
}

choose_multi() {
    local header="$1"
    shift
    gum choose --no-limit --header "$header" "$@"
}

show_spinner() {
    local title="$1"
    shift
    gum spin --spinner dot --title "$title" -- "$@"
}

show_header() {
    gum style \
        --border normal \
        --padding "1 2" \
        --border-foreground 212 \
        --bold \
        "$1"
}

# Logging
log_info() {
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $1" >&2
}

log_warning() {
    echo "[WARN] $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        return 0
    else
        return 1
    fi
}

# Check if a command exists
command_exists() {
    command -v "$1" &>/dev/null
}
