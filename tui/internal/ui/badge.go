package ui

import "github.com/reisset/mypctools/tui/internal/theme"

// InstalledBadge returns a green checkmark badge.
func InstalledBadge() string {
	return theme.BadgeInstalledStyle().Render(" ✓")
}
