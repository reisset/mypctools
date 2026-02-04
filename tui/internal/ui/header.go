package ui

import (
	"strings"

	"github.com/charmbracelet/lipgloss"
	"github.com/reisset/mypctools/tui/internal/theme"
)

// Breadcrumb renders "Parent > Parent > Current" with muted parents and primary current.
func Breadcrumb(titles []string) string {
	if len(titles) == 0 {
		return ""
	}
	if len(titles) == 1 {
		return theme.SubheaderStyle().Render(titles[0])
	}

	muted := theme.MutedStyle()
	sep := muted.Render(" > ")

	var parts []string
	for i, t := range titles {
		if i < len(titles)-1 {
			parts = append(parts, muted.Render(t))
		} else {
			parts = append(parts, theme.SubheaderStyle().Render(t))
		}
	}

	// Join parents on one line, then the boxed current title below
	parents := strings.Join(parts[:len(parts)-1], sep)
	current := parts[len(parts)-1]

	return lipgloss.JoinVertical(lipgloss.Left,
		lipgloss.NewStyle().MarginLeft(1).Render(parents),
		current,
	)
}
