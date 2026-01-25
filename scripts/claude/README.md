# Claude Code Setup

Personal Claude Code config: preferences, custom statusline, and document skills.

Part of [mypctools](https://github.com/reisset/mypctools) - run from the main TUI or directly:

```bash
./scripts/claude/install.sh
```

Then restart your shell to get the `cdsp` alias.

## What Gets Installed

- `~/.claude/CLAUDE.md` - Global preferences
- `~/.claude/statusline.sh` - Custom status bar (model, context %, git branch)
- `~/.claude/skills/` - Document handling skills (pdf, docx, xlsx, pptx, bloat-remover)
- `cdsp` alias - Shortcut for `claude --dangerously-skip-permissions`
