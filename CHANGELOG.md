# Changelog

## [Unreleased]

### Added
- Fedora/dnf support in `install_package()` - Fedora users now get native package manager instead of falling through to flatpak
- Design decisions section in CLAUDE.md documenting curl|bash fallback approach

### Removed
- Caligula ISO burner from CLI Utilities menu (niche, rarely used)
- Stale tool references from bash/uninstall.sh: zellij, bandwhich, hyperfine, tokei (removed from installer but still in uninstaller)

### Fixed
- Fedora support was broken: `get_package_manager()` returned "dnf" but `install_package()` didn't handle it

### Changed
- scripts/claude/README.md now references mypctools as canonical source instead of external repo

---

## [Previous Unreleased]

### Removed
- Deleted unused gum wrapper functions from lib/helpers.sh: `confirm_action()`, `choose_option()`, `choose_multi()`, `show_header()` (superseded by theme.sh functions)
- Deleted unused `log_warning()` from lib/helpers.sh
- Deleted unused `print_distro_info()` from lib/distro-detect.sh
- Deleted unused `themed_spin()` from lib/theme.sh (project uses `run_with_spinner` instead)
- Removed empty `configs/` directory

### Added
- Discord to Media apps menu (pacman/flatpak/deb fallback)
- `ensure_sudo()` helper function to pre-authenticate sudo before gum spin commands

### Fixed
- README.md: Corrected Caligula fallback method from "cargo install" to "GitHub binary release"
- gum spin hanging indefinitely after package installations complete (stdin not redirected)
- sudo password prompts hanging inside gum spin (now pre-authenticates with `ensure_sudo`)
- .NET SDK installation: case statement mismatch prevented menu selection from executing
- .NET SDK detection: `is_installed` now correctly checks for `dotnet` command

### Changed
- .NET SDK updated from version 8 to version 10 (current LTS)
- .NET SDK fallback simplified for Ubuntu 24.04+ (uses default repos, no Microsoft repo needed)
