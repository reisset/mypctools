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
	Suffix      string // Pre-styled suffix text (badges, hints) — right-aligned
	Description string // Dimmed second line below label
	Dimmed      bool   // Whether item should be dimmed
	Separator   bool   // Render as a separator line (not selectable)
}

// ListConfig configures list rendering.
type ListConfig struct {
	Width         int  // Total width for centering/sizing
	ShowCursor    bool // Retained for compatibility; ignored — the bar is always the cursor
	MaxInnerWidth int  // Max content line width (0 = default)
	Height        int  // Max visible items (0 = unlimited); windows around cursor when set
}

// RenderList renders a list using the Zen highlight-bar style.
// Selected items: cyan │ left accent + subtle highlight background.
// Unselected items: plain text indented to align.
func RenderList(items []ListItem, cursor int, cfg ListConfig) string {
	if len(items) == 0 {
		return ""
	}

	// Window items around cursor when height is constrained.
	if cfg.Height > 0 && len(items) > cfg.Height {
		half := cfg.Height / 2
		start := cursor - half
		if start < 0 {
			start = 0
		}
		end := start + cfg.Height
		if end > len(items) {
			end = len(items)
			start = end - cfg.Height
			if start < 0 {
				start = 0
			}
		}
		items = items[start:end]
		cursor = cursor - start
	}

	// Determine inner line width (total chars per row).
	innerWidth := cfg.Width
	if innerWidth == 0 {
		innerWidth = theme.ListInnerWidthMax
	}
	maxInner := cfg.MaxInnerWidth
	if maxInner == 0 {
		maxInner = theme.ListInnerWidthMax
	}
	if innerWidth > maxInner {
		innerWidth = maxInner
	}

	// Content area width = inner width minus padding.
	// Selected:    │ (1) + PadL(1) + content + PadR(1) = innerWidth  → content = innerWidth-3
	// Not selected: PadL(2) + content + PadR(1)         = innerWidth  → content = innerWidth-3
	contentWidth := innerWidth - 3
	if contentWidth < 10 {
		contentWidth = 10
	}

	bar := lipgloss.NewStyle().Foreground(lipgloss.Color(theme.Current.Border)).Render("│")

	selectedBg := lipgloss.NewStyle().
		Background(lipgloss.Color(theme.Current.Highlight)).
		Foreground(lipgloss.Color("#ffffff")).
		Bold(true).
		PaddingLeft(1).
		PaddingRight(1)

	normalFg := lipgloss.NewStyle().
		Foreground(lipgloss.Color("#d4d4d4")).
		PaddingLeft(2).
		PaddingRight(1)

	dimmedFg := lipgloss.NewStyle().
		Foreground(lipgloss.Color(theme.Current.Muted)).
		PaddingLeft(2).
		PaddingRight(1)

	descStyle := lipgloss.NewStyle().
		Foreground(lipgloss.Color(theme.Current.Muted)).
		PaddingLeft(2)

	var sb strings.Builder
	for i, item := range items {
		if i > 0 {
			sb.WriteByte('\n')
		}

		if item.Separator {
			sepLen := innerWidth - 4
			if sepLen < 4 {
				sepLen = 4
			}
			sep := "  " + theme.HelpDividerStyle().Render(strings.Repeat("─", sepLen))
			sb.WriteString(sep)
			continue
		}

		isSelected := i == cursor

		// Build label string with icon prefix.
		label := item.Label
		if item.Icon != "" {
			label = item.Icon + "  " + item.Label
		}

		// Right-align suffix within content area.
		if item.Suffix != "" {
			labelLen := lipgloss.Width(label)
			suffixLen := lipgloss.Width(item.Suffix)
			gap := contentWidth - labelLen - suffixLen
			if gap < 2 {
				gap = 2
			}
			label = label + strings.Repeat(" ", gap) + item.Suffix
		}

		var line string
		if isSelected {
			content := selectedBg.Width(innerWidth - 1).Render(label)
			line = bar + content
		} else {
			style := normalFg
			if item.Dimmed {
				style = dimmedFg
			}
			line = style.Width(innerWidth).Render(label)
		}

		sb.WriteString(line)

		// Description as indented second line.
		if item.Description != "" {
			desc := descStyle.Width(innerWidth).Render(item.Description)
			sb.WriteString("\n" + desc)
		}
	}

	return sb.String()
}
