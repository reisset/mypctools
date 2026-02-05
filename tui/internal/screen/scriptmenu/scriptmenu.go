package scriptmenu

import (
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/reisset/mypctools/tui/internal/app"
	"github.com/reisset/mypctools/tui/internal/bundle"
	"github.com/reisset/mypctools/tui/internal/screen/exec"
	"github.com/reisset/mypctools/tui/internal/state"
	"github.com/reisset/mypctools/tui/internal/theme"
	"github.com/reisset/mypctools/tui/internal/ui"
)

type menuItem struct {
	icon  string
	label string
	id    string
}

// Model is the install/uninstall menu for a specific bundle.
type Model struct {
	shared *state.Shared
	bundle bundle.Bundle
	items  []menuItem
	cursor int
}

// New creates a script menu for the given bundle.
func New(shared *state.Shared, b bundle.Bundle) Model {
	return Model{
		shared: shared,
		bundle: b,
		items: []menuItem{
			{icon: theme.Icons.Apps, label: "Install", id: "install"},
			{icon: theme.Icons.Cleanup, label: "Uninstall", id: "uninstall"},
			{icon: theme.Icons.Back, label: "Back", id: "back"},
		},
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
		case "j", "down":
			m.cursor++
			if m.cursor >= len(m.items) {
				m.cursor = 0
			}
		case "k", "up":
			m.cursor--
			if m.cursor < 0 {
				m.cursor = len(m.items) - 1
			}
		case "enter", " ":
			return m, m.handleSelection(m.items[m.cursor].id)
		}
	}
	return m, nil
}

func (m Model) handleSelection(id string) tea.Cmd {
	switch id {
	case "install":
		return app.Navigate(exec.New(m.shared, m.bundle, "install"))
	case "uninstall":
		return app.Navigate(exec.New(m.shared, m.bundle, "uninstall"))
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

	// Title with bundle name
	title := theme.SubheaderStyle().Render(m.bundle.Name)
	titleBlock := lipgloss.NewStyle().
		Width(width).
		Align(lipgloss.Center).
		Render(title)

	// Description
	desc := theme.MutedStyle().Render(m.bundle.Description)

	// Status
	var status string
	if bundle.IsInstalled(&m.bundle) {
		status = theme.SuccessStyle().Render("Installed") + ui.InstalledBadge()
	} else {
		status = theme.MutedStyle().Render("Not installed")
	}

	infoBlock := lipgloss.NewStyle().
		Width(width).
		Align(lipgloss.Center).
		Render(desc + "\n" + status)

	// Build list items
	items := make([]ui.ListItem, len(m.items))
	for i, item := range m.items {
		items[i] = ui.ListItem{
			Icon:  item.icon,
			Label: item.label,
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

	return lipgloss.JoinVertical(lipgloss.Left,
		titleBlock,
		infoBlock,
		"",
		menuBlock,
	)
}

func (m Model) Title() string {
	return m.bundle.Name
}

func (m Model) ShortHelp() []string {
	return []string{"j/k navigate", "enter select"}
}
