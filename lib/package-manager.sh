#!/usr/bin/env bash
# mypctools/lib/package-manager.sh
# Package installation logic (apt/pacman primary, flatpak fallback)
# v0.1.0

# Source distro detection
_PKG_MGR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_PKG_MGR_DIR/distro-detect.sh"
source "$_PKG_MGR_DIR/helpers.sh"

# Get the appropriate package manager
get_package_manager() {
    case "$DISTRO_TYPE" in
        arch)
            echo "pacman"
            ;;
        debian)
            echo "apt"
            ;;
        fedora)
            echo "dnf"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Check if flatpak is available
has_flatpak() {
    command_exists flatpak
}

# Install a package
# Usage: install_package "Display Name" "apt_pkg" "pacman_pkg" "flatpak_id" "fallback_function"
# Any package field can be empty string "" to skip that method
install_package() {
    local display_name="$1"
    local apt_pkg="$2"
    local pacman_pkg="$3"
    local flatpak_id="$4"
    local fallback_fn="$5"

    local pkg_manager
    pkg_manager=$(get_package_manager)

    print_info "Installing $display_name..."

    # Try native package manager first
    case "$pkg_manager" in
        apt)
            if [[ -n "$apt_pkg" ]]; then
                if sudo apt install -y $apt_pkg; then
                    print_success "$display_name installed successfully"
                    return 0
                fi
                print_warning "apt install failed, trying fallback..."
            fi
            ;;
        pacman)
            if [[ -n "$pacman_pkg" ]]; then
                if sudo pacman -S --noconfirm $pacman_pkg; then
                    print_success "$display_name installed successfully"
                    return 0
                fi
                print_warning "pacman install failed, trying fallback..."
            fi
            ;;
    esac

    # Flatpak fallback
    if [[ -n "$flatpak_id" ]] && has_flatpak; then
        if flatpak install -y flathub $flatpak_id; then
            print_success "$display_name installed via Flatpak"
            return 0
        fi
        print_warning "Flatpak install failed..."
    fi

    # Manual fallback function
    if [[ -n "$fallback_fn" ]] && declare -f "$fallback_fn" &>/dev/null; then
        print_info "Running custom install for $display_name..."
        if $fallback_fn; then
            print_success "$display_name installed via fallback"
            return 0
        fi
    fi

    print_error "No installation method available for $display_name"
    return 1
}

# Batch install packages from a list
# Usage: install_packages "pkg1" "pkg2" "pkg3"
install_packages() {
    local failed=0
    for pkg in "$@"; do
        if ! install_package "$pkg" "$pkg" "$pkg" "" ""; then
            ((failed++))
        fi
    done
    return $failed
}
