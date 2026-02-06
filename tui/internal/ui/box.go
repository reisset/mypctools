package ui

import (
	"github.com/charmbracelet/lipgloss"
	"github.com/reisset/mypctools/tui/internal/theme"
)

// BoxConfig configures box rendering.
type BoxConfig struct {
	Title  string // Optional title rendered at top-left of border
	Width  int    // Box width (0 for auto)
	Active bool   // Whether box is focused/active (primary border vs dim)
}

// Box renders content in a rounded border box (btop-inspired).
// Active boxes have primary-colored border, inactive have dimmed border.
func Box(content string, cfg BoxConfig) string {
	var style lipgloss.Style
	if cfg.Active {
		style = theme.BoxActiveStyle()
	} else {
		style = theme.BoxStyle()
	}

	if cfg.Width > 0 {
		style = style.Width(cfg.Width)
	}

	rendered := style.Render(content)

	// If there's a title, we render it at the top-left inside the border
	if cfg.Title != "" {
		titleStyle := theme.BoxTitleStyle()
		title := titleStyle.Render(" " + cfg.Title + " ")

		// Get the rendered box as lines and inject the title into the top border
		lines := splitLines(rendered)
		if len(lines) > 0 {
			// Find position to insert title (after first border char)
			firstLine := lines[0]
			if len(firstLine) > 2 {
				// Replace part of top border with title
				borderColor := theme.Current.BorderDim
				if cfg.Active {
					borderColor = theme.Current.Border
				}
				borderStyle := lipgloss.NewStyle().Foreground(lipgloss.Color(borderColor))

				// Calculate position (after ╭─)
				titleLen := lipgloss.Width(title)
				if titleLen+4 < lipgloss.Width(firstLine) {
					newFirst := string([]rune(firstLine)[0:1]) + title + borderStyle.Render(string([]rune(firstLine)[1+titleLen:]))
					lines[0] = newFirst
					rendered = joinLines(lines)
				}
			}
		}
	}

	return rendered
}


// splitLines splits a string into lines.
func splitLines(s string) []string {
	var lines []string
	start := 0
	for i := 0; i < len(s); i++ {
		if s[i] == '\n' {
			lines = append(lines, s[start:i])
			start = i + 1
		}
	}
	if start < len(s) {
		lines = append(lines, s[start:])
	}
	return lines
}

// joinLines joins lines with newlines.
func joinLines(lines []string) string {
	result := ""
	for i, line := range lines {
		result += line
		if i < len(lines)-1 {
			result += "\n"
		}
	}
	return result
}
