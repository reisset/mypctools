package ui

import (
	"strings"

	"github.com/charmbracelet/lipgloss"
	"github.com/reisset/mypctools/tui/internal/theme"
)

// Breadcrumb renders "Parent > Parent > Current" with muted parents and primary current.
// Width is used to center the breadcrumb horizontally.
func Breadcrumb(titles []string, width int) string {
	if len(titles) == 0 {
		return ""
	}
	if len(titles) == 1 {
		boxed := theme.SubheaderStyle().Render(titles[0])
		return lipgloss.NewStyle().Width(width).Align(lipgloss.Center).Render(boxed)
	}

	muted := theme.MutedStyle()
	sep := muted.Render(" > ")

	var parentParts []string
	for i, t := range titles[:len(titles)-1] {
		_ = i
		parentParts = append(parentParts, muted.Render(t))
	}
	parents := strings.Join(parentParts, sep)
	current := theme.SubheaderStyle().Render(titles[len(titles)-1])

	// Center both lines
	centeredParents := lipgloss.NewStyle().Width(width).Align(lipgloss.Center).Render(parents)
	centeredCurrent := lipgloss.NewStyle().Width(width).Align(lipgloss.Center).Render(current)

	return lipgloss.JoinVertical(lipgloss.Center, centeredParents, centeredCurrent)
}
