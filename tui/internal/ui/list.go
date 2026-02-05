package ui

import (
	"strings"

	"github.com/charmbracelet/lipgloss"
	"github.com/reisset/mypctools/tui/internal/theme"
)

// ListItem represents a single item in a list.
type ListItem struct {
	Icon    string // Icon to display before label
	Label   string // Main text
	Suffix  string // Additional text (badges, hints) - already styled
	Dimmed  bool   // Whether item should be dimmed
}

// ListConfig configures list rendering.
type ListConfig struct {
	Width         int    // Total width for full-width highlights
	ShowCursor    bool   // Show arrow cursor on selected item
	HighlightFull bool   // Use full-width highlight bar
}

// RenderList renders a list of items with the cursor at the given position.
// Returns the rendered list and the content width used.
func RenderList(items []ListItem, cursor int, cfg ListConfig) string {
	if len(items) == 0 {
		return ""
	}

	// Calculate the maximum label width for alignment
	maxLabelWidth := 0
	for _, item := range items {
		labelLen := lipgloss.Width(item.Icon + "  " + item.Label)
		if labelLen > maxLabelWidth {
			maxLabelWidth = labelLen
		}
	}

	// Build content width for highlight bar
	contentWidth := cfg.Width
	if contentWidth == 0 {
		contentWidth = 60 // Reasonable default
	}
	// Limit content width for cleaner appearance
	innerWidth := contentWidth - 8 // Account for centering margins
	if innerWidth > 50 {
		innerWidth = 50
	}

	var lines []string
	for i, item := range items {
		isSelected := i == cursor

		// Build the label with icon
		label := item.Label
		if item.Icon != "" {
			label = item.Icon + "  " + item.Label
		}

		// Add suffix if present
		if item.Suffix != "" {
			// Pad label for alignment before adding suffix
			padded := label
			currentLen := lipgloss.Width(label)
			if currentLen < maxLabelWidth+2 {
				padded += strings.Repeat(" ", maxLabelWidth+2-currentLen)
			}
			label = padded + item.Suffix
		}

		var line string
		if isSelected {
			if cfg.HighlightFull {
				// Full-width highlight bar style
				highlight := theme.ListHighlightStyle().Width(innerWidth)
				if cfg.ShowCursor {
					cursorIcon := theme.MenuCursorStyle().Render(theme.Icons.Cursor + " ")
					line = cursorIcon + highlight.Render(label)
				} else {
					line = "  " + highlight.Render(label)
				}
			} else {
				// Simple bold style
				if cfg.ShowCursor {
					cursorIcon := theme.MenuCursorStyle().Render("> ")
					line = cursorIcon + theme.MenuSelectedStyle().Render(label)
				} else {
					line = "  " + theme.MenuSelectedStyle().Render(label)
				}
			}
		} else {
			if item.Dimmed {
				line = "   " + theme.ListDimmedStyle().Width(innerWidth).Render(label)
			} else {
				line = "   " + theme.ListNormalStyle().Width(innerWidth).Render(label)
			}
		}

		lines = append(lines, line)
	}

	return strings.Join(lines, "\n")
}

// RenderSimpleList renders a basic list without icons.
func RenderSimpleList(labels []string, cursor int, width int) string {
	items := make([]ListItem, len(labels))
	for i, label := range labels {
		items[i] = ListItem{Label: label}
	}
	return RenderList(items, cursor, ListConfig{
		Width:         width,
		ShowCursor:    true,
		HighlightFull: true,
	})
}
