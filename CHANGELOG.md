# Changelog

## [Unreleased]

### Removed
- Deleted unused gum wrapper functions from lib/helpers.sh: `confirm_action()`, `choose_option()`, `choose_multi()`, `show_header()` (superseded by theme.sh functions)
- Deleted unused `log_warning()` from lib/helpers.sh
- Deleted unused `print_distro_info()` from lib/distro-detect.sh
- Deleted unused `themed_spin()` from lib/theme.sh (project uses `run_with_spinner` instead)
- Removed empty `configs/` directory

### Fixed
- README.md: Corrected Caligula fallback method from "cargo install" to "GitHub binary release"
