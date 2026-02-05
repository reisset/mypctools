#!/usr/bin/env bash
# Shared shell setup — set a shell as the user's default
# Requires: print_status, print_success, print_error, print_warning from lib/print.sh

[[ -n "$_SHELL_SETUP_SH_LOADED" ]] && return 0
_SHELL_SETUP_SH_LOADED=1

# Usage: set_default_shell <shell_path>
# Example: set_default_shell "$(command -v zsh)"
set_default_shell() {
    local shell_path="$1"
    local shell_name
    shell_name=$(basename "$shell_path")

    if [[ -z "$shell_path" ]]; then
        print_error "No shell path provided"
        return 1
    fi

    # Check /etc/passwd directly (more reliable than $SHELL)
    local current_shell
    current_shell=$(getent passwd "$USER" | cut -d: -f7)

    if [[ "$current_shell" == "$shell_path" ]]; then
        print_success "$shell_name is already the default shell"
        return 0
    fi

    # Refresh sudo credentials (may have expired during long install)
    print_status "Requesting sudo for shell change..."
    if ! sudo -v; then
        print_error "Could not get sudo access for shell change"
        print_status "Please run manually: chsh -s $shell_path"
        return 1
    fi

    # Ensure shell is in /etc/shells
    if ! grep -q "^${shell_path}$" /etc/shells 2>/dev/null; then
        print_status "Adding $shell_name to /etc/shells..."
        echo "$shell_path" | sudo tee -a /etc/shells >/dev/null
    fi

    print_status "Setting $shell_name as default shell..."

    # Try chsh first, then usermod as fallback
    local changed=false
    if sudo chsh -s "$shell_path" "$USER" 2>/dev/null; then
        changed=true
    elif sudo usermod -s "$shell_path" "$USER" 2>/dev/null; then
        changed=true
    fi

    if [[ "$changed" == "true" ]]; then
        local new_shell
        new_shell=$(getent passwd "$USER" | cut -d: -f7)
        if [[ "$new_shell" == "$shell_path" ]]; then
            print_success "Set $shell_name as default shell"
            return 0
        fi
    fi

    print_warning "Could not change shell automatically. Run: chsh -s $shell_path"
    return 1
}
