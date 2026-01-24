#!/bin/bash
# Claude Code dotfiles installer
# v1.4 - Added fish shell support, fixed alias detection to use $SHELL

set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Installing Claude Code config from $REPO_DIR"

# Create directories
mkdir -p ~/.claude/skills ~/.claude/commands

# Symlink CLAUDE.md
ln -sf "$REPO_DIR/CLAUDE.md" ~/.claude/CLAUDE.md
echo "  Linked CLAUDE.md"

# Symlink skills (directories containing SKILL.md)
if [ -d "$REPO_DIR/skills" ]; then
    for skill in "$REPO_DIR/skills"/*/; do
        [ -d "$skill" ] || continue
        skill_name=$(basename "$skill")
        ln -sfn "$skill" ~/.claude/skills/"$skill_name"
        echo "  Linked skill: $skill_name"
    done
fi

# Symlink commands (skip hidden files like .gitkeep)
if [ -d "$REPO_DIR/commands" ]; then
    for cmd in "$REPO_DIR/commands"/*; do
        [ -e "$cmd" ] || continue
        cmd_name=$(basename "$cmd")
        [[ "$cmd_name" == .* ]] && continue
        ln -sf "$cmd" ~/.claude/commands/"$cmd_name"
        echo "  Linked command: $cmd_name"
    done
fi

# Symlink statusline script
if [ -f "$REPO_DIR/statusline.sh" ]; then
    ln -sf "$REPO_DIR/statusline.sh" ~/.claude/statusline.sh
    chmod +x ~/.claude/statusline.sh
    echo "  Linked statusline.sh"

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
