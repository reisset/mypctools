package ui

import "github.com/reisset/mypctools/tui/internal/theme"

// InstalledBadge returns a green checkmark badge.
func InstalledBadge() string {
	return " " + theme.SuccessStyle().Render(theme.Icons.Check)
}

// MethodBadge returns a muted "via apt/flatpak" hint.
func MethodBadge(method string) string {
	if method == "" {
		return ""
	}
	return theme.MutedStyle().Italic(true).Render("via " + method)
}

// StatusBadge returns a pill-style status indicator.
func StatusBadge(status string) string {
	switch status {
	case "active", "running":
		return theme.StatusActiveStyle().Render(status)
	case "failed", "error":
		return theme.StatusErrorStyle().Render(status)
	default:
		return theme.StatusInactiveStyle().Render(status)
	}
}

// EnabledBadge returns a styled enabled/disabled indicator.
func EnabledBadge(enabled string) string {
	if enabled == "enabled" {
		return theme.SuccessStyle().Render(enabled)
	}
	return theme.MutedStyle().Render(enabled)
}
