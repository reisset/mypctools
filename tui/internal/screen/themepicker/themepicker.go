package themepicker

import (
	"strings"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/reisset/mypctools/tui/internal/app"
	"github.com/reisset/mypctools/tui/internal/state"
	"github.com/reisset/mypctools/tui/internal/theme"
	"github.com/reisset/mypctools/tui/internal/ui"
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
		case "down", "j":
			m.cursor++
			if m.cursor >= len(theme.Presets) {
				m.cursor = 0
			}
		case "up", "k":
			m.cursor--
			if m.cursor < 0 {
				m.cursor = len(theme.Presets) - 1
			}
		case "enter", " ":
			selected := theme.Presets[m.cursor]
			theme.Current = selected
			theme.RebuildStyles()
			if err := theme.Save(selected.Name); err != nil {
				// Log error but don't block the UI - theme is already applied in memory
				_ = err // Theme save failed, but in-memory theme is still applied
			}
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
	title := theme.SubheaderStyle().Render("Choose Theme")
	titleBlock := lipgloss.NewStyle().
		Width(width).
		Align(lipgloss.Center).
		Render(title)

	// Build list items with color swatches
	items := make([]ui.ListItem, len(theme.Presets))
	for i, p := range theme.Presets {
		name := themeDisplayName(p.Name)
		var suffix string
		if p.Name == theme.Current.Name {
			suffix = theme.MutedStyle().Render(" (current)")
		}
		suffix += "  " + renderSwatch(p)

		items[i] = ui.ListItem{
			Icon:   theme.Icons.Theme,
			Label:  name,
			Suffix: suffix,
		}
	}

	menu := ui.RenderList(items, m.cursor, ui.ListConfig{
		Width:      width,
		ShowCursor: true,
	})

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
	return []string{"enter apply"}
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
