package ui

import (
	"github.com/charmbracelet/lipgloss"
	"github.com/reisset/mypctools/tui/internal/theme"
)

// ScreenHeader renders "← Title" for sub-screens.
// Arrow is muted; title is white + bold; left-aligned.
func ScreenHeader(title string, width int) string {
	arrow := theme.MutedStyle().Render("←")
	titleStr := lipgloss.NewStyle().
		Bold(true).
		Foreground(lipgloss.Color("#ffffff")).
		Render(title)
	content := arrow + "  " + titleStr
	return lipgloss.NewStyle().Width(width).PaddingLeft(1).Render(content)
}
