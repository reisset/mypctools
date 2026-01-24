---
name: bloat-remover
description: Scan project for dead code, duplicate features, unused imports. Aggressively remove bloat and update CHANGELOG.md + README.md to reflect current state.
allowed-tools: Read, Edit, Write, Grep, Glob, Bash
---

# Bloat Remover

Aggressively clean up project bloat and synchronize documentation.

## Workflow

### 1. Scan for Bloat
Search the entire project for:
- **Unused imports** - imports that are never referenced
- **Dead code** - functions/classes never called
- **Duplicate functions** - similar logic implemented multiple times
- **Commented-out code blocks** - old code left as comments
- **Unused dependencies** - packages in requirements/package.json not imported
- **Empty files** - files with no meaningful content
- **Redundant files** - duplicate or superseded files

### 2. Remove Aggressively
For each finding:
- Delete unused imports
- Remove dead functions/classes
- Consolidate duplicates (keep the better implementation)
- Delete commented-out code blocks
- Remove unused dependencies from manifests
- Delete empty/redundant files

Do NOT ask for confirmation. Act decisively.

### 3. Update CHANGELOG.md
Add or update a "Removed" section with today's date:
```markdown
## [Unreleased]

### Removed
- Deleted unused function `oldHelper()` from utils.py
- Removed dead import `unused_module`
- Consolidated duplicate validation logic
```

If CHANGELOG.md doesn't exist, create it.

### 4. Update README.md
Review README.md and update to reflect current project state:
- Remove references to deleted features
- Update feature lists to match actual functionality
- Fix any outdated installation/usage instructions
- Remove documentation for removed components

If README.md doesn't exist, skip this step.

## Language-Specific Checks

### Python
```bash
# Find unused imports (basic check)
grep -r "^import\|^from" --include="*.py" | # then cross-reference usage
```

### JavaScript/TypeScript
```bash
# Check for unused dependencies
npm ls --depth=0 2>/dev/null || true
```

### General
- Look for TODO/FIXME comments referencing removed features
- Check for orphaned test files testing deleted code
- Verify config files don't reference removed modules

## Output
After completion, provide a summary:
- Files modified
- Lines removed
- Dependencies cleaned
- Documentation updated
