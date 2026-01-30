#!/bin/bash
# Claude Code config installer
# v1.7 - Removed set -e for reliability

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Check for jq (required for settings.json manipulation)
if ! command -v jq &>/dev/null; then
    echo "Error: jq is required but not installed."
    echo "Install it with: apt install jq / pacman -S jq / dnf install jq"
    exit 1
fi

echo "Installing Claude Code config..."

# Create directories
mkdir -p ~/.claude/skills ~/.claude/commands

# Copy skills (directories containing SKILL.md)
if [ -d "$SCRIPT_DIR/skills" ]; then
    for skill in "$SCRIPT_DIR/skills"/*/; do
        [ -d "$skill" ] || continue
        skill_name=$(basename "$skill")
        # Remove existing (handles symlinks from older setups)
        rm -rf ~/.claude/skills/"$skill_name"
        cp -r "$skill" ~/.claude/skills/
        echo "  Installed skill: $skill_name"
    done
fi

# Copy commands (skip hidden files like .gitkeep)
if [ -d "$SCRIPT_DIR/commands" ]; then
    for cmd in "$SCRIPT_DIR/commands"/*; do
        [ -e "$cmd" ] || continue
        cmd_name=$(basename "$cmd")
        [[ "$cmd_name" == .* ]] && continue
        cp "$cmd" ~/.claude/commands/"$cmd_name"
        echo "  Installed command: $cmd_name"
    done
fi

# Copy statusline script
if [ -f "$SCRIPT_DIR/statusline.sh" ]; then
    cp "$SCRIPT_DIR/statusline.sh" ~/.claude/statusline.sh
    chmod +x ~/.claude/statusline.sh
    echo "  Installed statusline.sh"

    # Update settings.json with statusLine config
    SETTINGS_FILE=~/.claude/settings.json
    if [ -f "$SETTINGS_FILE" ]; then
        # Merge statusLine into existing settings
        tmp=$(mktemp)
        jq '. + {"statusLine": {"type": "command", "command": "~/.claude/statusline.sh", "padding": 0}}' "$SETTINGS_FILE" > "$tmp" && mv "$tmp" "$SETTINGS_FILE"
    else
        # Create new settings file
        echo '{"statusLine": {"type": "command", "command": "~/.claude/statusline.sh", "padding": 0}}' > "$SETTINGS_FILE"
    fi
    echo "  Configured statusLine in settings.json"
fi

# Add cdsp alias to all shell rc files (so switching shells doesn't lose the alias)
add_alias_if_missing() {
    local rc_file="$1"
    local alias_line="$2"
    local grep_pattern="$3"

    [[ ! -f "$rc_file" ]] && return
    if ! grep -q "$grep_pattern" "$rc_file" 2>/dev/null; then
        echo "" >> "$rc_file"
        echo "# Claude Code shortcut" >> "$rc_file"
        echo "$alias_line" >> "$rc_file"
        echo "  Added cdsp alias to $rc_file"
    else
        echo "  cdsp alias already exists in $rc_file"
    fi
}

# Bash
add_alias_if_missing ~/.bashrc "alias cdsp='claude --dangerously-skip-permissions'" "alias cdsp="

# Zsh
add_alias_if_missing ~/.zshrc "alias cdsp='claude --dangerously-skip-permissions'" "alias cdsp="

# Fish (create config if fish dir exists but config doesn't)
if [[ -d ~/.config/fish ]]; then
    [[ ! -f ~/.config/fish/config.fish ]] && touch ~/.config/fish/config.fish
    add_alias_if_missing ~/.config/fish/config.fish "alias cdsp 'claude --dangerously-skip-permissions'" "alias cdsp "
fi

echo ""
echo "Done! Restart your shell and Claude Code to apply changes."
