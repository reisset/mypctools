#!/bin/bash
# Claude Code config installer
# v1.6 - Removed CLAUDE.md (users manage their own), added jq check

set -e

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

# Add cdsp alias to shell rc file
# Check user's default shell, not the script's running shell
if [[ "$SHELL" == */fish ]]; then
    RC_FILE=~/.config/fish/config.fish
    ALIAS_LINE="alias cdsp 'claude --dangerously-skip-permissions'"
    GREP_PATTERN="alias cdsp "
    mkdir -p ~/.config/fish
elif [[ "$SHELL" == */zsh ]]; then
    RC_FILE=~/.zshrc
    ALIAS_LINE="alias cdsp='claude --dangerously-skip-permissions'"
    GREP_PATTERN="alias cdsp="
elif [[ "$SHELL" == */bash ]]; then
    RC_FILE=~/.bashrc
    ALIAS_LINE="alias cdsp='claude --dangerously-skip-permissions'"
    GREP_PATTERN="alias cdsp="
fi

if [ -n "$RC_FILE" ]; then
    if ! grep -q "$GREP_PATTERN" "$RC_FILE" 2>/dev/null; then
        echo "" >> "$RC_FILE"
        echo "# Claude Code shortcut" >> "$RC_FILE"
        echo "$ALIAS_LINE" >> "$RC_FILE"
        echo "  Added cdsp alias to $RC_FILE"
    else
        echo "  cdsp alias already exists in $RC_FILE"
    fi
fi

echo ""
echo "Done! Restart your shell and Claude Code to apply changes."
