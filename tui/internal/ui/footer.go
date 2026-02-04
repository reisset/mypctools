package ui

import (
	"strings"

	"github.com/charmbracelet/lipgloss"
	"github.com/reisset/mypctools/tui/internal/theme"
)

// HelpKey is a single key binding hint.
type HelpKey struct {
	Key  string
	Desc string
}

// Footer renders a help key bar at the bottom.
func Footer(keys []HelpKey, width int) string {
	muted := theme.MutedStyle()
	accent := lipgloss.NewStyle().Foreground(lipgloss.Color(theme.Current.Secondary))

	var parts []string
	for _, k := range keys {
		parts = append(parts, accent.Render(k.Key)+" "+muted.Render(k.Desc))
	}

	bar := strings.Join(parts, muted.Render("  ·  "))
	return lipgloss.NewStyle().
		Width(width).
		Align(lipgloss.Center).
		Render(bar)
}
