#!/bin/bash
# Claude Code statusline - matches Starship theme
# v1.0 - Model, context %, git branch, directory

# Read JSON from stdin
input=$(cat)

# Extract data
model=$(echo "$input" | jq -r '.model.display_name // "Claude"')
context_pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0')
current_dir=$(echo "$input" | jq -r '.workspace.current_dir // "~"')

# Shorten home directory for display
dir="${current_dir/#$HOME/\~}"

# Get git branch (if in repo)
git_branch=$(git -C "$current_dir" branch --show-current 2>/dev/null || true)

# Colors (ANSI truecolor - matching Starship palette)
GRAY='\033[38;2;120;124;153m'      # #787c99
CYAN='\033[38;2;22;244;208m'       # #16f4d0
LCYAN='\033[38;2;159;255;245m'     # #9ffff5
ORANGE='\033[38;2;241;127;41m'     # #f17f29
YELLOW='\033[38;2;237;246;125m'    # #edf67d
RED='\033[38;2;206;66;87m'         # #ce4257
RESET='\033[0m'

# Context color based on usage (50% yellow, 70% red)
if [ "$context_pct" -ge 70 ]; then
    CTX_COLOR="$RED"
elif [ "$context_pct" -ge 50 ]; then
    CTX_COLOR="$YELLOW"
else
    CTX_COLOR="$CYAN"
fi

# Build output
output="${GRAY}╭╴${RESET} "
output+="${CYAN}${model}${RESET}"
output+=" ${GRAY}│${RESET} "
output+="${CTX_COLOR}ctx ${context_pct}%${RESET}"

if [ -n "$git_branch" ]; then
    output+=" ${GRAY}│${RESET} "
    output+="${ORANGE} ${git_branch}${RESET}"
fi

output+=" ${GRAY}│${RESET} "
output+="${LCYAN}${dir}${RESET}"

printf "%b" "$output"
