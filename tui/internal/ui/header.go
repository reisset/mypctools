package ui

import (
	"github.com/charmbracelet/lipgloss"
	"github.com/reisset/mypctools/tui/internal/theme"
)

// Breadcrumb renders "Parent / Parent / Current" inline.
// Parents are muted, current is primary + bold, separator is " / " in muted.
func Breadcrumb(titles []string, width int) string {
	if len(titles) == 0 {
		return ""
	}

	muted := theme.MutedStyle()
	primary := theme.SubheaderStyle() // Bold primary
	sep := muted.Render(" / ")

	var result string

	for i, title := range titles {
		if i == len(titles)-1 {
			// Current (last) item - primary + bold
			result += primary.Render(title)
		} else {
			// Parent items - muted
			result += muted.Render(title)
			result += sep
		}
	}

	return lipgloss.NewStyle().
		Width(width).
		Align(lipgloss.Center).
		Render(result)
}
