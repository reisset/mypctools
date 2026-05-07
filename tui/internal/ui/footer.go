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

// ParseHelpString splits a help string like "↑↓ navigate" into key and description.
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

// Footer renders a single centered line of key hints separated by ·
// No divider line above — just floating muted text.
func Footer(keys []HelpKey, width int) string {
	if len(keys) == 0 {
		return ""
	}

	keyStyle := theme.HelpKeyStyle()
	descStyle := theme.HelpDescStyle()
	dotStyle := theme.HelpDividerStyle()
	dot := dotStyle.Render(" · ")

	var parts []string
	for _, k := range keys {
		if k.Desc != "" {
			parts = append(parts, keyStyle.Render(k.Key)+" "+descStyle.Render(k.Desc))
		} else {
			parts = append(parts, keyStyle.Render(k.Key))
		}
	}

	helpText := strings.Join(parts, dot)

	return lipgloss.NewStyle().
		Width(width).
		Align(lipgloss.Center).
		Render(helpText)
}
