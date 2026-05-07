#!/usr/bin/env bash
# LiteZsh Shell Installer
# v1.6.0 - Removed set -e for reliability, explicit error handling

# NOTE: We intentionally do NOT use 'set -e' here.
# The script must complete all critical steps (symlinks, .zshrc, shell change)
# even if optional steps fail (individual package installs, etc.)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LITEZSH_DIR="$HOME/.local/share/litezsh"
LOCAL_BIN="$HOME/.local/bin"
ARCH=$(uname -m)

source "$SCRIPT_DIR/../../lib/print.sh"

trap 'print_error "Interrupted — partial install may have occurred."; exit 130' INT TERM

init_sudo

source "$SCRIPT_DIR/../../lib/distro-detect.sh"

# Install zsh
install_zsh() {
    if command -v zsh &>/dev/null; then
        print_success "zsh already installed"
        return 0
    fi

    print_status "Installing zsh..."
    $PKG_INSTALL zsh || { print_error "Failed to install zsh"; return 1; }

    if command -v zsh &>/dev/null; then
        print_success "Installed zsh"
    else
        print_error "zsh installation failed"
        return 1
    fi
}

source "$SCRIPT_DIR/../../lib/shell-setup.sh"

# Install zsh plugins via git
install_plugins() {
    local plugins_dir="$LITEZSH_DIR/plugins"
    mkdir -p "$plugins_dir"

    # zsh-autosuggestions
    if [[ -d "$plugins_dir/zsh-autosuggestions" ]]; then
        print_success "zsh-autosuggestions already installed"
    else
        print_status "Installing zsh-autosuggestions..."
        if git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git \
            "$plugins_dir/zsh-autosuggestions" 2>/dev/null; then
            print_success "Installed zsh-autosuggestions"
        else
            print_warning "Failed to install zsh-autosuggestions (optional)"
        fi
    fi

    # zsh-syntax-highlighting
    if [[ -d "$plugins_dir/zsh-syntax-highlighting" ]]; then
        print_success "zsh-syntax-highlighting already installed"
    else
        print_status "Installing zsh-syntax-highlighting..."
        if git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git \
            "$plugins_dir/zsh-syntax-highlighting" 2>/dev/null; then
            print_success "Installed zsh-syntax-highlighting"
        else
            print_warning "Failed to install zsh-syntax-highlighting (optional)"
        fi
    fi
}

# Install package via package manager
pkg_install() {
    local name="$1"
    local pacman_pkg="$2"
    local apt_pkg="$3"

    local pkg=""
    case "$PKG_MGR" in
        pacman) pkg="$pacman_pkg" ;;
        apt) pkg="$apt_pkg" ;;
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

    check_network

    # Create directories
    mkdir -p "$LOCAL_BIN"
    mkdir -p "$LITEZSH_DIR"
    mkdir -p "$HOME/.config"
    mkdir -p "$HOME/.cache/zsh"

    # Update package database
    print_status "Updating package database..."
    $PKG_UPDATE || print_warning "Package database update had issues (continuing anyway)"

    # Install zsh (required — everything else depends on it)
    install_zsh || { print_error "Cannot continue without zsh. Aborting."; return 1; }

    # Install dependencies
    print_status "Installing dependencies..."
    pkg_install "curl" "curl" "curl"
    pkg_install "unzip" "unzip" "unzip"
    pkg_install "tar" "tar" "tar"
    pkg_install "git" "git" "git"

    # Install plugins
    install_plugins

    # Install core tools via package manager
    print_status "Installing core tools..."
    pkg_install "eza" "eza" "eza"
    pkg_install "bat" "bat" "bat"
    pkg_install "fzf" "fzf" "fzf"
    pkg_install "ripgrep" "ripgrep" "ripgrep"
    pkg_install "fd" "fd" "fd-find"
    pkg_install "btop" "btop" "btop"
    pkg_install "micro" "micro" "micro"
    pkg_install "gh" "github-cli" "gh"

    # Create Debian symlinks + install all GitHub tools
    create_debian_symlinks
    install_all_tools

    # Symlink config files (source of truth in repo, aliases and TOOLS.md are shared)
    print_status "Installing LiteZsh config..."
    local symlink_errors=0
    safe_symlink "$SCRIPT_DIR/litezsh.zsh" "$LITEZSH_DIR/litezsh.zsh" "litezsh.zsh" || ((symlink_errors++))
    safe_symlink "$SCRIPT_DIR/../shared/shell/aliases.sh" "$LITEZSH_DIR/aliases.sh" "aliases.sh" || ((symlink_errors++))
    safe_symlink "$SCRIPT_DIR/functions.zsh" "$LITEZSH_DIR/functions.zsh" "functions.zsh" || ((symlink_errors++))
    safe_symlink "$SCRIPT_DIR/completions.zsh" "$LITEZSH_DIR/completions.zsh" "completions.zsh" || ((symlink_errors++))
    safe_symlink "$SCRIPT_DIR/../shared/shell/TOOLS.md" "$LITEZSH_DIR/TOOLS.md" "TOOLS.md" || ((symlink_errors++))

    # Verify ALL symlinks were created and point to valid targets
    local expected_links=("litezsh.zsh" "aliases.sh" "functions.zsh" "completions.zsh" "TOOLS.md")
    local verified=0
    for link in "${expected_links[@]}"; do
        if [[ -L "$LITEZSH_DIR/$link" ]] && [[ -e "$LITEZSH_DIR/$link" ]]; then
            ((verified++))
        fi
    done

    if [[ $verified -eq ${#expected_links[@]} ]]; then
        print_success "LiteZsh config installed ($verified/${#expected_links[@]} symlinks verified)"
    else
        print_error "Only $verified/${#expected_links[@]} symlinks verified - check permissions"
    fi

    # Install starship config (shared location)
    install_starship_config

    # Verify starship config was created
    if [[ ! -L "$HOME/.config/starship.toml" ]] && [[ ! -f "$HOME/.config/starship.toml" ]]; then
        print_warning "Starship config not created - creating manually..."
        ln -sf "$(readlink -f "$SCRIPT_DIR/../shared/prompt/starship.toml")" "$HOME/.config/starship.toml"
    fi

    # Set up .zshrc BEFORE changing shell (prevents zsh newuser wizard)
    # If .zshrc exists and has conflicting configs (oh-my-zsh, p10k, distro configs),
    # back it up and write a clean one. Otherwise just append.
    local needs_clean_zshrc=false
    if [[ -f "$HOME/.zshrc" ]]; then
        if grep -qE '(oh-my-zsh|powerlevel10k|p10k|cachyos-config|ENABLE_CORRECTION)' "$HOME/.zshrc" 2>/dev/null; then
            needs_clean_zshrc=true
        fi
    fi

    if [[ "$needs_clean_zshrc" == "true" ]]; then
        print_warning "Existing .zshrc has conflicting configs (oh-my-zsh/p10k/distro)"
        print_warning "LiteZsh needs a clean .zshrc — your current one will be backed up to ~/.zshrc.pre-litezsh"
        read -rp "Overwrite ~/.zshrc? [y/N] " _confirm
        if [[ ! "$_confirm" =~ ^[Yy]$ ]]; then
            print_warning "Skipping .zshrc replacement — manual setup may be required"
            needs_clean_zshrc=false
        fi
        unset _confirm
    fi

    if [[ "$needs_clean_zshrc" == "true" ]]; then
        print_status "Backing up to ~/.zshrc.pre-litezsh"
        cp "$HOME/.zshrc" "$HOME/.zshrc.pre-litezsh"

        # Preserve any user PATH/alias lines that aren't part of the conflicting framework
        print_status "Writing clean .zshrc..."
        cat > "$HOME/.zshrc" << 'ZSHRC'
export PATH="$HOME/.local/bin:$PATH"

# LiteZsh
[[ -f ~/.local/share/litezsh/litezsh.zsh ]] && source ~/.local/share/litezsh/litezsh.zsh
ZSHRC
        print_success "Clean .zshrc created (backup: ~/.zshrc.pre-litezsh)"
    elif ! grep -q "litezsh/litezsh.zsh" "$HOME/.zshrc" 2>/dev/null; then
        print_status "Adding LiteZsh to ~/.zshrc..."
        touch "$HOME/.zshrc"
        echo '' >> "$HOME/.zshrc"
        echo '# LiteZsh' >> "$HOME/.zshrc"
        echo '[[ -f ~/.local/share/litezsh/litezsh.zsh ]] && source ~/.local/share/litezsh/litezsh.zsh' >> "$HOME/.zshrc"
    else
        print_status "LiteZsh already in ~/.zshrc"
    fi

    # Set zsh as default shell (after .zshrc is set up)
    set_default_shell "$(command -v zsh)"

    echo ""
    print_success "Installation complete!"
    echo ""
    echo -e "${YELLOW}╔════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║  LOG OUT AND BACK IN to start using zsh!   ║${NC}"
    echo -e "${YELLOW}╚════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Or run 'zsh' to try it now without logging out."
    echo "Type 'tools' to see the quick reference."
}

main "$@"
