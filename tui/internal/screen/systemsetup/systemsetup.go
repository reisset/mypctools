package systemsetup

import (
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/reisset/mypctools/tui/internal/app"
	"github.com/reisset/mypctools/tui/internal/screen/cleanup"
	"github.com/reisset/mypctools/tui/internal/screen/services"
	"github.com/reisset/mypctools/tui/internal/screen/update"
	"github.com/reisset/mypctools/tui/internal/state"
	"github.com/reisset/mypctools/tui/internal/theme"
	"github.com/reisset/mypctools/tui/internal/ui"
)

type menuItem struct {
	icon      string
	label     string
	desc      string
	id        string
	separator bool
}

// Model is the system setup menu screen.
type Model struct {
	shared *state.Shared
	items  []menuItem
	cursor int
}

func New(shared *state.Shared) Model {
	items := []menuItem{
		{icon: "⟳", label: "Full System Update", desc: "runs pacman / apt upgrade", id: "update"},
		{icon: "✕", label: "System Cleanup", desc: "orphans, caches, trash", id: "cleanup"},
		{icon: "◎", label: "Service Manager", desc: "browse systemd services", id: "services"},
		{separator: true},
		{icon: "←", label: "Back", id: "back"},
	}
	return Model{shared: shared, items: items, cursor: 0}
}

func (m Model) Init() tea.Cmd { return nil }

func (m Model) Update(msg tea.Msg) (app.Screen, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "down":
			for range len(m.items) {
				m.cursor++
				if m.cursor >= len(m.items) {
					m.cursor = 0
				}
				if !m.items[m.cursor].separator {
					break
				}
			}
		case "up":
			for range len(m.items) {
				m.cursor--
				if m.cursor < 0 {
					m.cursor = len(m.items) - 1
				}
				if !m.items[m.cursor].separator {
					break
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

	subtitle := lipgloss.NewStyle().
		Foreground(lipgloss.Color(theme.Current.Muted)).
		Width(width).
		Align(lipgloss.Center).
		Render("system maintenance and configuration")

	items := make([]ui.ListItem, len(m.items))
	for i, item := range m.items {
		items[i] = ui.ListItem{
			Icon:        item.icon,
			Label:       item.label,
			Description: item.desc,
			Separator:   item.separator,
		}
	}

	menu := ui.RenderList(items, m.cursor, ui.ListConfig{
		Width:         60,
		MaxInnerWidth: 60,
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
	return "System Setup"
}

func (m Model) HandlesBack() bool { return false }

func (m Model) ShortHelp() []string {
	return []string{"↑↓ navigate", "enter select"}
}
