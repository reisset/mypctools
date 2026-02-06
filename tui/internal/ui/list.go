package ui

import (
	"strings"

	"github.com/charmbracelet/lipgloss"
	"github.com/reisset/mypctools/tui/internal/theme"
)

// ListItem represents a single item in a list.
type ListItem struct {
	Icon        string // Icon to display before label
	Label       string // Main text
	Suffix      string // Additional text (badges, hints) - already styled
	Description string // Rendered as dimmed second line below label
	Dimmed      bool   // Whether item should be dimmed
	Separator   bool   // Render as a separator line (not selectable)
}

// ListConfig configures list rendering.
type ListConfig struct {
	Width         int  // Total width for full-width highlights
	ShowCursor    bool // Show arrow cursor on selected item
	HighlightFull bool // Use full-width highlight bar
	MaxInnerWidth int  // Max content width (0 = default 50)
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
		contentWidth = theme.ListWidthDefault
	}
	// Limit content width for cleaner appearance
	innerWidth := contentWidth - 8 // Account for centering margins
	maxInner := cfg.MaxInnerWidth
	if maxInner == 0 {
		maxInner = theme.ListInnerWidthMax
	}
	if innerWidth > maxInner {
		innerWidth = maxInner
	}

	const cursorWidth = theme.ListCursorWidth

	var sb strings.Builder
	for i, item := range items {
		if i > 0 {
			sb.WriteByte('\n')
		}

		// Separator items render as a thin muted line, optionally with a label
		if item.Separator {
			var sepLine string
			if item.Label != "" {
				label := theme.MutedStyle().Bold(true).Render(item.Label)
				labelWidth := lipgloss.Width(label)
				remaining := innerWidth - labelWidth - 6 // "── " + " " + trailing dashes
				if remaining < 4 {
					remaining = 4
				}
				sepLine = strings.Repeat(" ", cursorWidth) +
					theme.MutedStyle().Render("── ") + label +
					theme.MutedStyle().Render(" "+strings.Repeat("─", remaining))
			} else {
				sepLine = strings.Repeat(" ", cursorWidth) +
					theme.MutedStyle().Render(theme.ListSeparator)
			}
			sb.WriteString(sepLine)
			continue
		}

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

		// Center content when item has a description
		hasDesc := item.Description != ""

		var line string
		if isSelected {
			if cfg.HighlightFull {
				// Full-width highlight bar style
				highlight := theme.ListHighlightStyle().Width(innerWidth)
				if hasDesc {
					highlight = highlight.Align(lipgloss.Center)
				}
				if cfg.ShowCursor {
					cursorStr := lipgloss.NewStyle().
						Width(cursorWidth).
						Foreground(lipgloss.Color(theme.Current.Primary)).
						Render(theme.Icons.Cursor)
					line = cursorStr + highlight.Render(label)
				} else {
					spacer := strings.Repeat(" ", cursorWidth)
					line = spacer + highlight.Render(label)
				}
			} else {
				// Simple bold style
				if cfg.ShowCursor {
					cursorStr := lipgloss.NewStyle().
						Width(cursorWidth).
						Foreground(lipgloss.Color(theme.Current.Primary)).
						Render(">")
					line = cursorStr + theme.MenuSelectedStyle().Render(label)
				} else {
					spacer := strings.Repeat(" ", cursorWidth)
					line = spacer + theme.MenuSelectedStyle().Render(label)
				}
			}

		} else {
			spacer := strings.Repeat(" ", cursorWidth)
			if item.Dimmed {
				style := theme.ListDimmedStyle().Width(innerWidth)
				if hasDesc {
					style = style.Align(lipgloss.Center)
				}
				line = spacer + style.Render(label)
			} else {
				style := theme.ListNormalStyle().Width(innerWidth)
				if hasDesc {
					style = style.Align(lipgloss.Center)
				}
				line = spacer + style.Render(label)
			}
		}

		sb.WriteString(line)

		// Render description as a centered dimmed second line
		if hasDesc {
			descStyle := theme.MutedStyle()
			if isSelected && cfg.HighlightFull {
				descStyle = descStyle.Italic(true)
			}
			descLine := strings.Repeat(" ", cursorWidth) +
				lipgloss.NewStyle().Width(innerWidth).Align(lipgloss.Center).
					Render(descStyle.Render(item.Description))
			sb.WriteString("\n" + descLine)
		}
	}

	return sb.String()
}

// SkipSeparator adjusts cursor to skip separator items.
// direction: +1 for down, -1 for up.
func SkipSeparator(items []ListItem, cursor int, direction int) int {
	if cursor >= 0 && cursor < len(items) && items[cursor].Separator {
		cursor += direction
		if cursor >= len(items) {
			cursor = 0
		} else if cursor < 0 {
			cursor = len(items) - 1
		}
	}
	return cursor
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
