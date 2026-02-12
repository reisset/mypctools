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
	idx := strings.Index(s, " ")
	if idx == -1 {
		return HelpKey{Key: s, Desc: ""}
	}
	return HelpKey{
		Key:  s[:idx],
		Desc: s[idx+1:],
	}
}

// Footer renders a help key bar with a divider above.
// Keys are rendered as pill badges with subtle backgrounds.
func Footer(keys []HelpKey, width int) string {
	keyStyle := theme.HelpKeyPillStyle()
	descStyle := theme.HelpDescStyle()
	dividerStyle := theme.HelpDividerStyle()

	// Build help text with pill-style keys
	var parts []string
	for _, k := range keys {
		parts = append(parts, keyStyle.Render(k.Key)+" "+descStyle.Render(k.Desc))
	}

	helpText := strings.Join(parts, "  ")

	// Create divider line
	dividerWidth := width - 4
	if dividerWidth > theme.FooterDividerMax {
		dividerWidth = theme.FooterDividerMax
	}
	if dividerWidth < theme.FooterDividerMin {
		dividerWidth = theme.FooterDividerMin
	}
	divider := dividerStyle.Render(strings.Repeat("─", dividerWidth))

	// Center both
	dividerCentered := lipgloss.NewStyle().
		Width(width).
		Align(lipgloss.Center).
		Render(divider)

	helpCentered := lipgloss.NewStyle().
		Width(width).
		Align(lipgloss.Center).
		Render(helpText)

	return dividerCentered + "\n" + helpCentered
}
