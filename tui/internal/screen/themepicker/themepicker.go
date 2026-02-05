package themepicker

import (
	"strings"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/reisset/mypctools/tui/internal/app"
	"github.com/reisset/mypctools/tui/internal/state"
	"github.com/reisset/mypctools/tui/internal/theme"
)

// Model is the theme picker screen.
type Model struct {
	shared *state.Shared
	cursor int
}

// New creates a new theme picker screen.
func New(shared *state.Shared) Model {
	// Set cursor to current theme
	cursor := 0
	for i, p := range theme.Presets {
		if p.Name == theme.Current.Name {
			cursor = i
			break
		}
	}
	return Model{
		shared: shared,
		cursor: cursor,
	}
}

func (m Model) Init() tea.Cmd {
	return nil
}

func (m Model) Update(msg tea.Msg) (app.Screen, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "j", "down":
			m.cursor++
			if m.cursor >= len(theme.Presets) {
				m.cursor = 0
			}
		case "k", "up":
			m.cursor--
			if m.cursor < 0 {
				m.cursor = len(theme.Presets) - 1
			}
		case "enter", " ":
			selected := theme.Presets[m.cursor]
			theme.Current = selected
			theme.RebuildStyles()
			_ = theme.Save(selected.Name)
			return m, app.PopScreen()
		}
	}
	return m, nil
}

func (m Model) View() string {
	width := m.shared.TerminalWidth
	if width == 0 {
		width = 80
	}

	// Title
	title := lipgloss.NewStyle().
		Foreground(lipgloss.Color(theme.Current.Primary)).
		Bold(true).
		Render("Choose Theme")

	titleBlock := lipgloss.NewStyle().
		Width(width).
		Align(lipgloss.Center).
		Render(title)

	// Theme options with color swatches
	var lines []string
	cursor := theme.MenuCursorStyle()
	normal := theme.MenuItemStyle()
	selected := theme.MenuSelectedStyle()

	for i, p := range theme.Presets {
		// Build color swatch - show all 7 colors
		swatch := renderSwatch(p)

		// Theme name with friendly display
		name := themeDisplayName(p.Name)
		if p.Name == theme.Current.Name {
			name += " (current)"
		}

		if i == m.cursor {
			line := cursor.Render("> ") + selected.Render(name) + "  " + swatch
			lines = append(lines, line)
		} else {
			lines = append(lines, "  "+normal.Render(name)+"  "+swatch)
		}
	}
	menu := strings.Join(lines, "\n")

	menuBlock := lipgloss.NewStyle().
		Width(width).
		Align(lipgloss.Center).
		Render(menu)

	return lipgloss.JoinVertical(lipgloss.Left,
		titleBlock,
		"",
		menuBlock,
	)
}

func (m Model) Title() string {
	return "Theme"
}

func (m Model) ShortHelp() []string {
	return []string{"j/k navigate", "enter select"}
}

// renderSwatch creates color preview blocks for a palette.
func renderSwatch(p theme.Palette) string {
	colors := []string{p.Primary, p.Secondary, p.Muted, p.Success, p.Warning, p.Error, p.Accent}
	var blocks []string
	for _, c := range colors {
		block := lipgloss.NewStyle().
			Background(lipgloss.Color(c)).
			Render("  ")
		blocks = append(blocks, block)
	}
	return strings.Join(blocks, "")
}

// themeDisplayName returns a user-friendly name for a theme.
func themeDisplayName(name string) string {
	switch name {
	case "default":
		return "Default (Cyan)"
	case "catppuccin":
		return "Catppuccin Mocha"
	case "tokyo-night":
		return "Tokyo Night"
	default:
		return name
	}
}
