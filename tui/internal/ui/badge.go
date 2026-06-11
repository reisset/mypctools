package ui

import (
	"github.com/charmbracelet/lipgloss"
	"github.com/reisset/mypctools/tui/internal/theme"
)

// InstalledBadge returns a subtle green "✓ installed" text indicator.
func InstalledBadge() string {
	return lipgloss.NewStyle().
		Foreground(lipgloss.Color(theme.Current.Success)).
		Render("✓ installed")
}
