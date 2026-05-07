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

// StatusBadge returns a colored status indicator for services.
func StatusBadge(status string) string {
	switch status {
	case "active", "running":
		return theme.StatusActiveStyle().Render("● " + status)
	case "failed", "error":
		return theme.StatusErrorStyle().Render("✕ " + status)
	default:
		return theme.StatusInactiveStyle().Render("○ " + status)
	}
}

// EnabledBadge returns a styled enabled/disabled indicator.
func EnabledBadge(enabled string) string {
	if enabled == "enabled" {
		return theme.SuccessStyle().Render(enabled)
	}
	return theme.MutedStyle().Render(enabled)
}
