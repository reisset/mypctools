#!/bin/bash
# Claude Code config uninstaller
# v1.0 - Reverses install.sh changes

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

confirm() {
    echo -ne "${YELLOW}[?] $1 (y/N) ${NC}"
    read -r response
    [[ "$response" =~ ^[Yy]$ ]]
}

echo "Uninstalling Claude Code config..."
echo ""

# Check if anything is installed
if [ ! -d "$HOME/.claude" ]; then
    log_warn "~/.claude directory not found. Nothing to uninstall."
    exit 0
fi

# Remove skills
if [ -d "$HOME/.claude/skills" ]; then
    # Only remove skills that came from this repo
    for skill in "$SCRIPT_DIR/skills"/*/; do
        [ -d "$skill" ] || continue
        skill_name=$(basename "$skill")
        if [ -d "$HOME/.claude/skills/$skill_name" ]; then
            rm -rf "$HOME/.claude/skills/$skill_name"
            log_info "Removed skill: $skill_name"
        fi
    done
fi

# Remove commands
if [ -d "$HOME/.claude/commands" ] && [ -d "$SCRIPT_DIR/commands" ]; then
    for cmd in "$SCRIPT_DIR/commands"/*; do
        [ -e "$cmd" ] || continue
        cmd_name=$(basename "$cmd")
        [[ "$cmd_name" == .* ]] && continue
        if [ -f "$HOME/.claude/commands/$cmd_name" ]; then
            rm "$HOME/.claude/commands/$cmd_name"
            log_info "Removed command: $cmd_name"
        fi
    done
fi

# Remove statusline.sh
if [ -f "$HOME/.claude/statusline.sh" ]; then
    rm "$HOME/.claude/statusline.sh"
    log_info "Removed statusline.sh"
fi

# Remove statusLine from settings.json
SETTINGS_FILE="$HOME/.claude/settings.json"
if [ -f "$SETTINGS_FILE" ] && command -v jq &>/dev/null; then
    if jq -e '.statusLine' "$SETTINGS_FILE" &>/dev/null; then
        tmp=$(mktemp)
        jq 'del(.statusLine)' "$SETTINGS_FILE" > "$tmp" && mv "$tmp" "$SETTINGS_FILE"
        log_info "Removed statusLine from settings.json"
    fi
fi

# Remove cdsp alias from shell rc files
remove_alias_from_rc() {
    local rc_file="$1"
    local pattern="$2"

    if [ -f "$rc_file" ] && grep -q "$pattern" "$rc_file" 2>/dev/null; then
        # Create backup
        cp "$rc_file" "$rc_file.claude-backup-$(date +%Y%m%d-%H%M%S)"
        # Remove alias line and comment
        sed -i '/# Claude Code shortcut/d' "$rc_file"
        sed -i "/$pattern/d" "$rc_file"
        log_info "Removed cdsp alias from $rc_file"
        return 0
    fi
    return 1
}

# Check each shell rc file
remove_alias_from_rc "$HOME/.bashrc" "alias cdsp=" || true
remove_alias_from_rc "$HOME/.zshrc" "alias cdsp=" || true
remove_alias_from_rc "$HOME/.config/fish/config.fish" "alias cdsp " || true

echo ""
log_info "Uninstall complete!"
log_warn "Restart your shell to apply changes."
