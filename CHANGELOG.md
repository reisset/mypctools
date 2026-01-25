# Changelog

## [Unreleased]

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
