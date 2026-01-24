# claudesetup

Personal Claude Code config: preferences, custom statusline, and document skills.

## Quick Start

```bash
git clone git@github.com:reisset/claudesetup.git ~/claudesetup && ~/claudesetup/install.sh
```

Then restart your shell to get the `cdsp` alias.

## What Gets Installed

- `~/.claude/CLAUDE.md` - Global preferences
- `~/.claude/statusline.sh` - Custom status bar (model, context %, git branch)
- `~/.claude/skills/` - Document handling skills (pdf, docx, xlsx, pptx, bloat-remover)
- `cdsp` alias - Shortcut for `claude --dangerously-skip-permissions`
