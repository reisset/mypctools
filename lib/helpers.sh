#!/usr/bin/env bash
# mypctools/lib/helpers.sh
# Shared helper functions for mypctools
# v0.2.0

# Source theme
_HELPERS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_HELPERS_DIR/theme.sh"

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

# Logging
log_info() {
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $1" >&2
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

# Ensure sudo credentials are cached (prompts user if needed)
# Call this BEFORE running sudo commands inside gum spin
ensure_sudo() {
    if ! sudo -v; then
        print_error "sudo authentication failed"
        return 1
    fi
}
