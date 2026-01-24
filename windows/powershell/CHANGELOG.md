# Changelog

All notable changes to MyPowerShell will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.4.1] - 2026-01-16

### Fixed
- **Installer Optional Tools Output**: Fixed cosmetic bugs in optional tool installation
  - Removed duplicate "Installing X via scoop..." messages (yazi, tealdeer, glow)
  - Suppressed stray "True" output from `Install-ScoopPackage` return values
  - Fixed jq and gsudo silent installations - now use helper functions with proper success messages
  - Made summary text consistent - removed "(if installed)" from optional tools list

## [1.4.0] - 2026-01-16

### Fixed
- **Starship Caching Bug**: Fixed critical bug where cache stored wrapper command instead of actual init script
  - Cache contained `Invoke-Expression (& starship.exe init powershell --print-full-init)` which still spawned starship.exe every time
  - Now correctly caches the full init script using `--print-full-init` flag
  - Saves ~100-200ms per profile load

### Added
- **Tool Availability Caching**: Cache Get-Command results to file for 7 days
  - New cache file: `$env:TEMP\mypowershell-tools.json`
  - Avoids expensive PATH scanning on every shell startup
  - Saves ~50-100ms per profile load

### Changed
- **Profile Load Time**: Reduced from ~531ms warm / ~1000ms cold to **~42ms warm / ~270ms cold**
  - 92% faster warm boot, 73% faster cold boot
  - Removed explicit PSReadLine import (auto-loaded in PowerShell 7)
  - Combined all performance fixes for dramatic improvement

## [1.3.0] - 2026-01-16

### Added
- **glow**: Markdown viewer for beautiful terminal rendering (completes incomplete feature)
- **jq**: JSON processor with `jqc` convenience function for parsing clipboard JSON
- **gsudo**: Windows elevation tool providing `sudo` alias for elevating commands without new window

### Fixed
- **glow Integration**: Fixed bug where glow was checked in profile but never offered for installation
  - Added to optional tools section in installer alongside yazi/tealdeer
  - Added to uninstaller removal logic
  - `tools` command now uses glow for pretty markdown rendering when available

### Changed
- Updated installer to prompt for glow, jq, and gsudo installation
- Updated profile batch check to include jq and gsudo
- Updated TOOLS.md with new tool documentation and usage examples

## [1.2.4] - 2026-01-09

### Fixed
- **Windows Terminal Font Configuration**: Fixed bug where font settings were not applied after fresh install
  - Installer used `@{}` (hashtable) instead of `[PSCustomObject]@{}` for `defaults` and `font` objects
  - NoteProperties added via `Add-Member` to hashtables don't serialize to JSON (only PSCustomObject properties do)
  - After uninstall + reinstall, font would remain on Cascadia Mono instead of JetBrainsMono Nerd Font size 15
  - Fixed by using `[PSCustomObject]@{}` in lines 424 and 432

## [1.2.3] - 2026-01-09

### Fixed
- **Installer Hook Detection**: Fixed critical bug where empty profile after uninstall would not have hook re-added
  - `$null -notlike "*pattern*"` returns empty array in PowerShell, which evaluates to `$false`
  - Added explicit null check: `if (-not $existingContent -or $existingContent -notlike "*$profileSource*")`
  - Fixes issue where after running uninstaller, re-running installer would say "hook already exists" but leave profile empty
  - This caused all features (Starship, zoxide, aliases, ASCII art) to not work after fresh install

## [1.2.2] - 2026-01-09

### Changed
- **Installer Output**: Removed redundant text from completion message
  - Removed "Phase 3" references from banner and version comments
  - Removed duplicate "v1.0 installation complete" status line
  - Removed "Quick Start" section (delegated to `tools` command)
- **README**: Added missing tools (`dust`, `y`, `tldr`) to Quick Reference

## [1.1.2] - 2026-01-09

### Fixed
- **Uninstaller**: Fixed scoop false-positive bug where tools showed as uninstalled when they weren't
  - Scoop returns exit code 0 even with "isn't installed" error message
  - Added pattern check for "isn't installed" in scoop output before marking as successful
  - Applies to core, dev, and optional tool uninstallation loops

### Changed
- **Uninstaller Output**: Polished to match installer formatting style
  - Header now uses Unicode box-drawing characters (removed version number)
  - Consolidated end section into single green completion banner
  - Changed bullet points from `-` to `•` for consistency
  - Removed redundant separator boxes for cleaner output

## [1.1.1] - 2026-01-08

### Fixed
- **Uninstaller**: Fixed profile hook removal failure due to regex pattern mismatch
- **Profile Cache**: Added error handling with fallback to direct init if cache creation fails

## [1.2.1] - 2026-01-08

### Fixed
- **Windows .exe Extension Handling**: Fixed starship prompt detection after v1.2.0 batch optimization
  - Batch `Get-Command` returns `starship.exe` on Windows, not `starship`
  - Updated tool availability check to handle both forms

## [1.2.0] - 2026-01-08

### Changed
- **Profile Load Time**: Reduced from <250ms (v1.1.0) to ~150-200ms
  - Optimized batch `Get-Command` (single call instead of 9)
  - Removed unnecessary PSReadLine check (~20-40ms saved)
  - Combined PSReadLineOption calls
  - Used faster .NET file APIs instead of PowerShell cmdlets
  - Added Starship timeout configurations (prevents hangs)

### Fixed
- **`lsg` Function**: Fixed severe performance issue with many files
  - Changed from spawning eza per file to single batch call

## [1.1.0] - 2026-01-08

### Changed
- **Profile Load Time**: Reduced from ~500ms to <250ms (~50% improvement)
  - Batch command availability checks (~150ms saved)
  - Cached init scripts for starship and zoxide (~100ms saved)
  - Cache regenerates every 7 days or if missing

### Added
- **CLAUDE.md**: Project context file for development
- **.gitignore**: Spec file and temporary file entries

### Fixed
- **Installer**: Fixed `Confirm-No` function not found error

## [1.0.0] - 2026-01-08

### Added
- **Documentation**: README.md, TOOLS.md, LICENSE (MIT), SECURITY.md
- **Yazi Integration**: File manager wrapper (`y` command) with directory change support
- **Optional Tools**: Yazi and tealdeer (prompted during installation)

### Changed
- Updated installer completion message to reference v1.0
- Added comprehensive "Next steps" guide

## Early Development (0.1.0 - 0.3.1)

**Phase 1 (0.1.0)**: Foundation
- Starship prompt with Tokyo Night theme
- PSReadLine enhancements (history prediction, ListView mode)
- Installer with Scoop and winget support

**Phase 2 (0.2.0)**: Core Tools
- Added zoxide, fzf + PSFzf, eza, bat, fd, ripgrep
- Created aliases.ps1 with tool shortcuts and git commands
- Automatic tool loading with graceful degradation

**Phase 3 (0.3.0)**: Development Tools & Visual Polish
- Added lazygit, delta, dust
- Windows Terminal Tokyo Night theme integration
- JetBrainsMono Nerd Font installation
- Removed Terminal-Icons module (performance optimization)

**Phase 3.5 (0.3.1)**: Bug Fixes & Polish
- Fixed `Add-Member` errors in installer
- Increased default font size to 15pt
- Added ASCII art welcome banner (once per session)

---

## Installation

```powershell
cd C:\Users\YourUsername\mypowershell
.\install.ps1
```

After installation, restart your terminal or run:
```powershell
. $PROFILE
```
