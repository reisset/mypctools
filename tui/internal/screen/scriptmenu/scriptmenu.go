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
	shared     *state.Shared
	bundle     bundle.Bundle
	installed  bool
	items      []menuItem
	cursor     int
	confirming bool
}

func New(shared *state.Shared, b bundle.Bundle) Model {
	installed := bundle.IsInstalled(&b)
	return Model{
		shared:    shared,
		bundle:    b,
		installed: installed,
		items:     buildItems(installed),
		cursor:    0,
	}
}

func buildItems(installed bool) []menuItem {
	if installed {
		return []menuItem{
			{icon: "⟳", label: "Reinstall", id: "install"},
			{icon: "✕", label: "Uninstall", id: "uninstall"},
			{icon: "←", label: "Back", id: "back"},
		}
	}
	return []menuItem{
		{icon: "+", label: "Install", id: "install"},
		{icon: "←", label: "Back", id: "back"},
	}
}

func (m Model) Init() tea.Cmd { return nil }

func (m Model) Update(msg tea.Msg) (app.Screen, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		if m.confirming {
			switch msg.String() {
			case "y", "Y":
				m.confirming = false
				return m, app.Navigate(exec.New(m.shared, m.bundle, "uninstall"))
			case "n", "N", "esc":
				m.confirming = false
			}
			return m, nil
		}

		switch msg.String() {
		case "down":
			m.cursor++
			if m.cursor >= len(m.items) {
				m.cursor = 0
			}
		case "up":
			m.cursor--
			if m.cursor < 0 {
				m.cursor = len(m.items) - 1
			}
		case "enter", " ":
			if m.cursor < len(m.items) {
				id := m.items[m.cursor].id
				if id == "uninstall" {
					m.confirming = true
					return m, nil
				}
				return m, m.handleSelection(id)
			}
		}
	}
	return m, nil
}

func (m Model) handleSelection(id string) tea.Cmd {
	switch id {
	case "install":
		return app.Navigate(exec.New(m.shared, m.bundle, "install"))
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

	// Title + description block (centered)
	titleStyle := lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("#ffffff"))
	var titleLine string
	if m.installed {
		badge := ui.InstalledBadge()
		titleLine = titleStyle.Render(m.bundle.Name) + "  " + badge
	} else {
		titleLine = titleStyle.Render(m.bundle.Name)
	}

	titleBlock := lipgloss.NewStyle().Width(width).Align(lipgloss.Center).Render(titleLine)
	descBlock := lipgloss.NewStyle().
		Width(width).
		Align(lipgloss.Center).
		Foreground(lipgloss.Color(theme.Current.Muted)).
		Render(m.bundle.Description)

	if m.confirming {
		confirmMsg := theme.WarningStyle().Render("Uninstall " + m.bundle.Name + "?")
		hint := theme.MutedStyle().Render("y confirm · n cancel")
		return lipgloss.JoinVertical(lipgloss.Left,
			titleBlock,
			descBlock,
			"",
			lipgloss.NewStyle().Width(width).Align(lipgloss.Center).Render(confirmMsg),
			lipgloss.NewStyle().Width(width).Align(lipgloss.Center).Render(hint),
		)
	}

	// Build list: insert separator before last item (Back).
	listItems := make([]ui.ListItem, 0, len(m.items)+1)
	for i, item := range m.items {
		if i == len(m.items)-1 {
			listItems = append(listItems, ui.ListItem{Separator: true})
		}
		listItems = append(listItems, ui.ListItem{Icon: item.icon, Label: item.label})
	}

	// The separator is before the last item (Back), so shift cursor past it.
	listCursor := m.cursor
	if m.cursor == len(m.items)-1 {
		listCursor = m.cursor + 1
	}
	menu := ui.RenderList(listItems, listCursor, ui.ListConfig{
		Width:         48,
		MaxInnerWidth: 48,
	})

	menuBlock := lipgloss.NewStyle().Width(width).Align(lipgloss.Center).Render(menu)

	return lipgloss.JoinVertical(lipgloss.Left,
		titleBlock,
		descBlock,
		"",
		menuBlock,
	)
}

func (m Model) Title() string {
	return m.bundle.Name
}

func (m Model) HandlesBack() bool { return m.confirming }

func (m Model) ShortHelp() []string {
	if m.confirming {
		return []string{"y confirm", "n cancel"}
	}
	return []string{"enter confirm"}
}
