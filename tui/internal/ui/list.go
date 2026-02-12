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
	Width         int  // Total width for layout
	ShowCursor    bool // Show arrow cursor on selected item
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
				label := theme.MutedStyle().Render(item.Label)
				labelWidth := lipgloss.Width(label)
				rightDash := innerWidth - labelWidth - 5 // 3 left dashes + 2 spaces
				if rightDash < 2 {
					rightDash = 2
				}
				sepLine = strings.Repeat(" ", cursorWidth) +
					theme.MutedStyle().Render("─── ") + label +
					theme.MutedStyle().Render(" "+strings.Repeat("─", rightDash))
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

		hasDesc := item.Description != ""

		var line string
		if isSelected {
			selected := theme.MenuSelectedStyle().Width(innerWidth)
			if cfg.ShowCursor {
				cursorStr := lipgloss.NewStyle().
					Width(cursorWidth).
					Foreground(lipgloss.Color(theme.Current.Primary)).
					Render(theme.Icons.Cursor)
				line = cursorStr + selected.Render(label)
			} else {
				spacer := strings.Repeat(" ", cursorWidth)
				line = spacer + selected.Render(label)
			}
		} else {
			spacer := strings.Repeat(" ", cursorWidth)
			if item.Dimmed {
				line = spacer + theme.ListDimmedStyle().Width(innerWidth).Render(label)
			} else {
				line = spacer + theme.ListNormalStyle().Width(innerWidth).Render(label)
			}
		}

		sb.WriteString(line)

		// Render description as a dimmed second line, indented to match label
		if hasDesc {
			descLine := strings.Repeat(" ", cursorWidth) +
				lipgloss.NewStyle().Width(innerWidth).PaddingLeft(theme.PadItemH).
					Render(theme.MutedStyle().Render(item.Description))
			sb.WriteString("\n" + descLine)
		}
	}

	return sb.String()
}

