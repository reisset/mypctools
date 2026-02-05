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

// ParseHelpString splits a help string like "j/k navigate" into key and description.
func ParseHelpString(s string) HelpKey {
	// Find the first space to split key from description
	idx := strings.Index(s, " ")
	if idx == -1 {
		return HelpKey{Key: s, Desc: ""}
	}
	return HelpKey{
		Key:  s[:idx],
		Desc: s[idx+1:],
	}
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
