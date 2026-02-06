package ui

import (
	"github.com/reisset/mypctools/tui/internal/theme"
)

// Checkbox renders a styled checkbox.
// Uses nerd font symbols when available, falls back to [x]/[ ].
func Checkbox(checked bool) string {
	if checked {
		return theme.SuccessStyle().Render(theme.Icons.CheckBoxOn)
	}
	return theme.MutedStyle().Render(theme.Icons.CheckBox)
}
