#!/bin/bash
# Claude Code statusline
# Git status • Context usage • Session timer

# Fallback if jq not available
if ! command -v jq &>/dev/null; then
    printf "statusline requires jq"
    exit 0
fi

# Read JSON from stdin
input=$(cat)

# Extract data
model=$(echo "$input" | jq -r '.model.display_name // "Claude"')
current_dir=$(echo "$input" | jq -r '.workspace.current_dir // "~"')
session_id=$(echo "$input" | jq -r '.session_id // ""')

# Context usage — use the pre-calculated used_percentage field directly
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# Shorten home directory for display
dir="${current_dir/#$HOME/\~}"

# Session duration
if [ -n "$session_id" ]; then
    session_file="/tmp/claude_session_${session_id}_start"
    current_time=$(date +%s)
    if [ ! -f "$session_file" ]; then
        echo "$current_time" > "$session_file"
        duration="0m"
    else
        start_time=$(cat "$session_file")
        elapsed=$((current_time - start_time))
        minutes=$((elapsed / 60))
        if [ "$minutes" -ge 60 ]; then
            hours=$((minutes / 60))
            mins=$((minutes % 60))
            duration="${hours}h${mins}m"
        else
            duration="${minutes}m"
        fi
    fi
else
    duration="0m"
fi

# Git status
export GIT_OPTIONAL_LOCKS=0
git_branch=""
git_dirty=false
total_changes=0
ahead=0
behind=0

if git -C "$current_dir" rev-parse --git-dir &>/dev/null; then
    git_branch=$(git -C "$current_dir" branch --show-current 2>/dev/null)
    [ -z "$git_branch" ] && git_branch="detached"

    if ! git -C "$current_dir" diff --quiet 2>/dev/null || \
       ! git -C "$current_dir" diff --cached --quiet 2>/dev/null; then
        git_dirty=true
        changed=$(git -C "$current_dir" diff --name-only 2>/dev/null | wc -l)
        staged=$(git -C "$current_dir" diff --cached --name-only 2>/dev/null | wc -l)
        total_changes=$((changed + staged))
    fi

    upstream=$(git -C "$current_dir" rev-parse --abbrev-ref @{upstream} 2>/dev/null)
    if [ -n "$upstream" ]; then
        ahead=$(git -C "$current_dir" rev-list --count @{upstream}..HEAD 2>/dev/null || echo "0")
        behind=$(git -C "$current_dir" rev-list --count HEAD..@{upstream} 2>/dev/null || echo "0")
    fi
fi

# Colors (ANSI truecolor - matching Starship palette)
GRAY='\033[38;2;120;124;153m'      # #787c99
CYAN='\033[38;2;22;244;208m'       # #16f4d0
LCYAN='\033[38;2;159;255;245m'     # #9ffff5
ORANGE='\033[38;2;241;127;41m'     # #f17f29
YELLOW='\033[38;2;237;246;125m'    # #edf67d
RED='\033[38;2;206;66;87m'         # #ce4257
GREEN='\033[38;2;42;195;125m'      # #2ac37d
PURPLE='\033[38;2;187;154;247m'    # #bb9af7
RESET='\033[0m'

# Context color based on used percentage
# Green <50%, yellow <70%, red >=70%
if [ -n "$used_pct" ]; then
    used_int=$(awk "BEGIN {printf \"%.0f\", $used_pct}")
    if [ "$used_int" -ge 70 ]; then
        CTX_COLOR="$RED"      # High usage: >=70%
    elif [ "$used_int" -ge 50 ]; then
        CTX_COLOR="$YELLOW"   # Moderate: >=50%
    else
        CTX_COLOR="$GREEN"    # Low: <50%
    fi
    ctx_display="CTX: ${used_int}%"
else
    CTX_COLOR="$GRAY"
    ctx_display="CTX: --"
fi

# Build output
output="${GRAY}╭╴${RESET} "

# Model
output+="${PURPLE}◆ ${model}${RESET}"
output+=" ${GRAY}│${RESET} "

# Context usage
output+="${CTX_COLOR}${ctx_display}${RESET}"
output+=" ${GRAY}│${RESET} "

# Session duration
output+="${CYAN}⏱ ${duration}${RESET}"

# Git status
if [ -n "$git_branch" ]; then
    output+=" ${GRAY}│${RESET} "
    output+="${ORANGE}⎇ ${git_branch}"
    if [ "$git_dirty" = true ]; then
        output+=" ${RED}✗${total_changes}"
    else
        output+=" ${GREEN}✓"
    fi
    output+="${RESET}"
    if [ "$ahead" -gt 0 ] || [ "$behind" -gt 0 ]; then
        output+="${GRAY}("
        [ "$ahead" -gt 0 ] && output+="${GREEN}↑${ahead}${RESET}"
        [ "$ahead" -gt 0 ] && [ "$behind" -gt 0 ] && output+="${GRAY}/"
        [ "$behind" -gt 0 ] && output+="${RED}↓${behind}${RESET}"
        output+="${GRAY})${RESET}"
    fi
fi

# Directory
output+=" ${GRAY}│${RESET} "
output+="${LCYAN}📁 ${dir}${RESET}"

printf "%b" "$output"
