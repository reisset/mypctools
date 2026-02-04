#!/usr/bin/env bash
# Safe symlink creation with validation and backup
# Requires: print_status, print_success, print_warning from lib/print.sh

[[ -n "$_SYMLINK_SH_LOADED" ]] && return 0
_SYMLINK_SH_LOADED=1

# Usage: safe_symlink <source> <target> [name]
# Returns 0 on success, 1 on failure
safe_symlink() {
    local source="$1"
    local target="$2"
    local name="${3:-$(basename "$target")}"

    # Resolve source to absolute path
    local resolved_source
    resolved_source=$(readlink -f "$source" 2>/dev/null)

    if [[ -z "$resolved_source" ]]; then
        print_warning "Could not resolve source path: $source"
        return 1
    fi

    if [[ ! -f "$resolved_source" ]]; then
        print_warning "Source file not found: $source"
        return 1
    fi

    # If target is already a symlink pointing to our source, skip
    if [[ -L "$target" ]]; then
        local current_target
        current_target=$(readlink -f "$target" 2>/dev/null)
        if [[ "$current_target" == "$resolved_source" ]]; then
            print_success "$name already configured"
            return 0
        fi
    fi

    # Backup existing file/symlink if it's not ours
    if [[ -e "$target" || -L "$target" ]]; then
        local backup="$target.backup.$(date +%Y%m%d_%H%M%S)"
        mv "$target" "$backup"
        print_status "Backed up existing $name to: $(basename "$backup")"
    fi

    # Create symlink
    if ln -sf "$resolved_source" "$target"; then
        print_success "Linked $name"
        return 0
    else
        print_warning "Failed to link $name"
        return 1
    fi
}
