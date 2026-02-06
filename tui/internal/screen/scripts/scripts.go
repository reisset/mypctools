package scripts

import (
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/reisset/mypctools/tui/internal/app"
	"github.com/reisset/mypctools/tui/internal/bundle"
	"github.com/reisset/mypctools/tui/internal/screen/scriptmenu"
	"github.com/reisset/mypctools/tui/internal/state"
	"github.com/reisset/mypctools/tui/internal/theme"
	"github.com/reisset/mypctools/tui/internal/ui"
)

// Model is the script bundles list screen.
type Model struct {
	shared  *state.Shared
	bundles []bundle.Bundle
	cursor  int
}

// New creates a new scripts list screen.
func New(shared *state.Shared) Model {
	return Model{
		shared:  shared,
		bundles: bundle.All(),
		cursor:  0,
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
			if m.cursor >= len(m.bundles) {
				m.cursor = 0
			}
		case "up", "k":
			m.cursor--
			if m.cursor < 0 {
				m.cursor = len(m.bundles) - 1
			}
		case "enter", " ":
			if m.cursor < len(m.bundles) {
				b := m.bundles[m.cursor]
				return m, app.Navigate(scriptmenu.New(m.shared, b))
			}
		}
	}
	return m, nil
}

func (m Model) View() string {
	width := m.shared.TerminalWidth
	if width == 0 {
		width = 80
	}

	// Subtitle
	subtitle := lipgloss.NewStyle().
		Foreground(lipgloss.Color(theme.Current.Muted)).
		Width(width).
		Align(lipgloss.Center).
		Render("Personal script bundles and configs")

	// Build list items
	items := make([]ui.ListItem, len(m.bundles))
	for i, b := range m.bundles {
		var suffix string
		if bundle.IsInstalled(&b) {
			suffix = ui.InstalledBadge() + "  " + theme.MutedStyle().Render(b.Description)
		} else {
			suffix = "     " + theme.MutedStyle().Render(b.Description)
		}
		items[i] = ui.ListItem{
			Icon:   theme.Icons.Scripts,
			Label:  b.Name,
			Suffix: suffix,
		}
	}

	menu := ui.RenderList(items, m.cursor, ui.ListConfig{
		Width:         width,
		ShowCursor:    true,
		HighlightFull: true,
		MaxInnerWidth: 80,
	})

	menuBlock := lipgloss.NewStyle().
		Width(width).
		Align(lipgloss.Center).
		Render(menu)

	return lipgloss.JoinVertical(lipgloss.Left,
		subtitle,
		"",
		menuBlock,
	)
}

func (m Model) Title() string {
	return "My Scripts"
}

func (m Model) ShortHelp() []string {
	return []string{"enter select"}
}
