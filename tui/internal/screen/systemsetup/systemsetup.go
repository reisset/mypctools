package systemsetup

import (
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/reisset/mypctools/tui/internal/app"
	"github.com/reisset/mypctools/tui/internal/screen/cleanup"
	"github.com/reisset/mypctools/tui/internal/screen/services"
	"github.com/reisset/mypctools/tui/internal/screen/themepicker"
	"github.com/reisset/mypctools/tui/internal/screen/update"
	"github.com/reisset/mypctools/tui/internal/state"
	"github.com/reisset/mypctools/tui/internal/theme"
	"github.com/reisset/mypctools/tui/internal/ui"
)

type menuItem struct {
	icon      string
	label     string
	id        string
	desc      string
	separator bool
}

// Model is the system setup menu screen.
type Model struct {
	shared *state.Shared
	items  []menuItem
	cursor int
}

// New creates a new system setup menu.
func New(shared *state.Shared) Model {
	items := []menuItem{
		{icon: theme.Icons.Update, label: "Full System Update", id: "update", desc: "Update all system packages"},
		{icon: theme.Icons.Cleanup, label: "System Cleanup", id: "cleanup", desc: "Remove unused packages and caches"},
		{icon: theme.Icons.Service, label: "Service Manager", id: "services", desc: "Start, stop, enable system services"},
		{separator: true},
		{icon: theme.Icons.Theme, label: "Theme", id: "theme", desc: "Switch color theme"},
		{icon: theme.Icons.Back, label: "Back", id: "back"},
	}
	return Model{
		shared: shared,
		items:  items,
		cursor: 0,
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
			if m.cursor >= len(m.items) {
				m.cursor = 0
			}
			if m.items[m.cursor].separator {
				m.cursor++
				if m.cursor >= len(m.items) {
					m.cursor = 0
				}
			}
		case "up", "k":
			m.cursor--
			if m.cursor < 0 {
				m.cursor = len(m.items) - 1
			}
			if m.items[m.cursor].separator {
				m.cursor--
				if m.cursor < 0 {
					m.cursor = len(m.items) - 1
				}
			}
		case "enter", " ":
			if !m.items[m.cursor].separator {
				return m, m.handleSelection(m.items[m.cursor].id)
			}
		}
	}
	return m, nil
}

func (m Model) handleSelection(id string) tea.Cmd {
	switch id {
	case "update":
		return app.Navigate(update.New(m.shared))
	case "cleanup":
		return app.Navigate(cleanup.New(m.shared))
	case "services":
		return app.Navigate(services.New(m.shared))
	case "theme":
		return app.Navigate(themepicker.New(m.shared))
	case "back":
		return app.PopScreen()
	}
	return nil
}

func (m Model) View() string {
	width := m.shared.TerminalWidth
	if width == 0 {
		width = 80
	}

	// Build list items
	items := make([]ui.ListItem, len(m.items))
	for i, item := range m.items {
		items[i] = ui.ListItem{
			Icon:      item.icon,
			Label:     item.label,
			Desc:      item.desc,
			Separator: item.separator,
		}
	}

	menu := ui.RenderList(items, m.cursor, ui.ListConfig{
		Width:         width,
		ShowCursor:    true,
		HighlightFull: true,
	})

	menuBlock := lipgloss.NewStyle().
		Width(width).
		Align(lipgloss.Center).
		Render(menu)

	return menuBlock
}

func (m Model) Title() string {
	return "System Setup"
}

func (m Model) ShortHelp() []string {
	return []string{"enter select"}
}
