#!/usr/bin/env bash
# LiteBash Shell Installer
# v1.4.0 - Removed set -e for reliability, explicit error handling

# NOTE: We intentionally do NOT use 'set -e' here.
# The script must complete all critical steps (config, .bashrc, shell change)
# even if optional steps fail (individual package installs, etc.)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LITEBASH_DIR="$HOME/.local/share/litebash"
LOCAL_BIN="$HOME/.local/bin"
ARCH=$(uname -m)

source "$SCRIPT_DIR/../../lib/print.sh"

init_sudo

source "$SCRIPT_DIR/../../lib/distro-detect.sh"

source "$SCRIPT_DIR/../../lib/shell-setup.sh"

# Install package via package manager
pkg_install() {
    local name="$1"
    local pacman_pkg="$2"
    local apt_pkg="$3"
    local dnf_pkg="$4"

    local pkg=""
    case "$PKG_MGR" in
        pacman) pkg="$pacman_pkg" ;;
        apt) pkg="$apt_pkg" ;;
        dnf) pkg="$dnf_pkg" ;;
    esac

    if [ -n "$pkg" ]; then
        print_status "Installing $name..."
        $PKG_INSTALL "$pkg" 2>/dev/null || print_warning "Failed to install $name via $PKG_MGR"
    fi
}

# Main installation
main() {
    print_status "Detected package manager: $PKG_MGR"

    # Source shared tool installation lib
    source "$SCRIPT_DIR/../../lib/tools-install.sh"

    # Create directories
    mkdir -p "$LOCAL_BIN"
    mkdir -p "$LITEBASH_DIR"
    mkdir -p "$HOME/.config"

    # Update package database
    print_status "Updating package database..."
    $PKG_UPDATE || print_warning "Package database update had issues (continuing anyway)"

    # Install dependencies
    print_status "Installing dependencies..."
    pkg_install "curl" "curl" "curl" "curl"
    pkg_install "unzip" "unzip" "unzip" "unzip"
    pkg_install "tar" "tar" "tar" "tar"
    pkg_install "git" "git" "git" "git"

    # Install core tools via package manager
    print_status "Installing core tools..."
    pkg_install "eza" "eza" "eza" "eza"
    pkg_install "bat" "bat" "bat" "bat"
    pkg_install "fzf" "fzf" "fzf" "fzf"
    pkg_install "ripgrep" "ripgrep" "ripgrep" "ripgrep"
    pkg_install "fd" "fd" "fd-find" "fd-find"
    pkg_install "btop" "btop" "btop" "btop"
    pkg_install "micro" "micro" "micro" "micro"
    pkg_install "gh" "github-cli" "gh" "gh"

    # Create Debian symlinks + install all GitHub tools
    create_debian_symlinks
    install_all_tools

    # Symlink config files (source of truth in repo, aliases and TOOLS.md are shared)
    print_status "Installing LiteBash config..."
    local symlink_errors=0
    safe_symlink "$SCRIPT_DIR/litebash.sh" "$LITEBASH_DIR/litebash.sh" "litebash.sh" || ((symlink_errors++))
    safe_symlink "$SCRIPT_DIR/../shared/shell/aliases.sh" "$LITEBASH_DIR/aliases.sh" "aliases.sh" || ((symlink_errors++))
    safe_symlink "$SCRIPT_DIR/functions.sh" "$LITEBASH_DIR/functions.sh" "functions.sh" || ((symlink_errors++))
    safe_symlink "$SCRIPT_DIR/../shared/shell/TOOLS.md" "$LITEBASH_DIR/TOOLS.md" "TOOLS.md" || ((symlink_errors++))

    # Verify ALL symlinks were created and point to valid targets
    local expected_links=("litebash.sh" "aliases.sh" "functions.sh" "TOOLS.md")
    local verified=0
    for link in "${expected_links[@]}"; do
        if [[ -L "$LITEBASH_DIR/$link" ]] && [[ -e "$LITEBASH_DIR/$link" ]]; then
            ((verified++))
        fi
    done

    if [[ $verified -eq ${#expected_links[@]} ]]; then
        print_success "LiteBash config installed ($verified/${#expected_links[@]} symlinks verified)"
    else
        print_warning "Only $verified/${#expected_links[@]} symlinks verified - check permissions"
    fi

    # Install starship config (shared location)
    install_starship_config

    # Verify starship config was created
    if [[ ! -L "$HOME/.config/starship.toml" ]] && [[ ! -f "$HOME/.config/starship.toml" ]]; then
        print_warning "Starship config not created - creating manually..."
        ln -sf "$(readlink -f "$SCRIPT_DIR/../shared/prompt/starship.toml")" "$HOME/.config/starship.toml"
    fi

    # Set up .bashrc BEFORE changing shell
    # If .bashrc has conflicting configs (oh-my-bash, bash-it, distro frameworks),
    # back it up and write a clean one. Otherwise just append.
    local needs_clean_bashrc=false
    if [[ -f "$HOME/.bashrc" ]]; then
        if grep -qE '(oh-my-bash|bash-it|OSH_THEME|BASH_IT|cachyos-config|powerline-shell)' "$HOME/.bashrc" 2>/dev/null; then
            needs_clean_bashrc=true
        fi
    fi

    if [[ "$needs_clean_bashrc" == "true" ]]; then
        print_warning "Existing .bashrc has conflicting configs (oh-my-bash/bash-it/distro)"
        print_status "Backing up to ~/.bashrc.pre-litebash"
        cp "$HOME/.bashrc" "$HOME/.bashrc.pre-litebash"

        print_status "Writing clean .bashrc..."
        cat > "$HOME/.bashrc" << 'BASHRC'
export PATH="$HOME/.local/bin:$PATH"

# LiteBash
[ -f ~/.local/share/litebash/litebash.sh ] && source ~/.local/share/litebash/litebash.sh
BASHRC
        print_success "Clean .bashrc created (backup: ~/.bashrc.pre-litebash)"
    elif ! grep -q "litebash/litebash.sh" "$HOME/.bashrc" 2>/dev/null; then
        print_status "Adding LiteBash to ~/.bashrc..."
        echo '' >> "$HOME/.bashrc"
        echo '# LiteBash' >> "$HOME/.bashrc"
        echo '[ -f ~/.local/share/litebash/litebash.sh ] && source ~/.local/share/litebash/litebash.sh' >> "$HOME/.bashrc"
    else
        print_status "LiteBash already in ~/.bashrc"
    fi

    # Set bash as default shell
    set_default_shell "$(command -v bash)"

    echo ""
    print_success "Installation complete!"
    echo ""
    echo "Restart your shell or run: source ~/.bashrc"
    echo "Type 'tools' to see the quick reference."
}

main "$@"
