package services

import (
	"fmt"
	"strings"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/reisset/mypctools/tui/internal/app"
	"github.com/reisset/mypctools/tui/internal/state"
	"github.com/reisset/mypctools/tui/internal/system"
	"github.com/reisset/mypctools/tui/internal/theme"
)

type menuItem struct {
	label string
	id    string
}

// Model is the service manager menu screen.
type Model struct {
	shared *state.Shared
	items  []menuItem
	cursor int
}

// New creates a new service manager menu.
func New(shared *state.Shared) Model {
	items := []menuItem{
		{label: theme.Icons.Service + "  Common Services", id: "common"},
		{label: "All Services", id: "all"},
		{label: theme.Icons.Back + "  Back", id: "back"},
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
	case "common":
		return app.Navigate(NewServiceList(m.shared, false))
	case "all":
		return app.Navigate(NewServiceList(m.shared, true))
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

	// Title
	title := lipgloss.NewStyle().
		Foreground(lipgloss.Color(theme.Current.Primary)).
		Bold(true).
		Render("Service Manager")

	titleBlock := lipgloss.NewStyle().
		Width(width).
		Align(lipgloss.Center).
		Render(title)

	// Menu items
	var menuLines []string
	cursor := theme.MenuCursorStyle()
	normal := theme.MenuItemStyle()
	selected := theme.MenuSelectedStyle()

	for i, item := range m.items {
		if i == m.cursor {
			line := cursor.Render("> ") + selected.Render(item.label)
			menuLines = append(menuLines, line)
		} else {
			menuLines = append(menuLines, "  "+normal.Render(item.label))
		}
	}
	menu := strings.Join(menuLines, "\n")

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
	return "Service Manager"
}

func (m Model) ShortHelp() []string {
	return []string{"j/k navigate", "enter select"}
}

// ServiceListModel shows a list of services with their status.
type ServiceListModel struct {
	shared   *state.Shared
	services []system.ServiceStatus
	cursor   int
	showAll  bool
	loading  bool
}

// servicesLoadedMsg is sent when service list is loaded.
type servicesLoadedMsg struct {
	services []system.ServiceStatus
}

// NewServiceList creates a new service list screen.
func NewServiceList(shared *state.Shared, showAll bool) ServiceListModel {
	return ServiceListModel{
		shared:  shared,
		showAll: showAll,
		loading: true,
	}
}

func (m ServiceListModel) Init() tea.Cmd {
	return m.loadServices()
}

func (m ServiceListModel) loadServices() tea.Cmd {
	return func() tea.Msg {
		if m.showAll {
			names, err := system.ListAllServices()
			if err != nil {
				return servicesLoadedMsg{services: nil}
			}
			var services []system.ServiceStatus
			for _, name := range names {
				services = append(services, system.GetServiceStatus(name))
			}
			return servicesLoadedMsg{services: services}
		}
		return servicesLoadedMsg{services: system.GetKnownServices()}
	}
}

func (m ServiceListModel) Update(msg tea.Msg) (app.Screen, tea.Cmd) {
	switch msg := msg.(type) {
	case servicesLoadedMsg:
		m.services = msg.services
		m.loading = false
		return m, nil

	case tea.KeyMsg:
		if m.loading {
			return m, nil
		}

		switch msg.String() {
		case "j", "down":
			m.cursor++
			if m.cursor >= len(m.services) {
				m.cursor = 0
			}
		case "k", "up":
			m.cursor--
			if m.cursor < 0 {
				m.cursor = len(m.services) - 1
			}
		case "enter", " ":
			if len(m.services) > 0 && m.cursor < len(m.services) {
				return m, app.Navigate(NewServiceDetail(m.shared, m.services[m.cursor].Name))
			}
		}
	}
	return m, nil
}

func (m ServiceListModel) View() string {
	width := m.shared.TerminalWidth
	if width == 0 {
		width = 80
	}

	if m.loading {
		loading := theme.MutedStyle().Render("Loading services...")
		return lipgloss.NewStyle().
			Width(width).
			Align(lipgloss.Center).
			Render(loading)
	}

	if len(m.services) == 0 {
		noServices := theme.WarningStyle().Render("No services found")
		prompt := theme.MutedStyle().Render("Press esc to go back")
		content := lipgloss.JoinVertical(lipgloss.Center, noServices, "", prompt)
		return lipgloss.NewStyle().
			Width(width).
			Align(lipgloss.Center).
			Render(content)
	}

	// Table header
	header := fmt.Sprintf("%-20s %-12s %-12s", "Service", "Status", "Enabled")
	headerStyle := lipgloss.NewStyle().
		Foreground(lipgloss.Color(theme.Current.Muted)).
		Bold(true)
	headerLine := headerStyle.Render(header)

	// Table rows
	var rows []string
	rows = append(rows, headerLine)
	rows = append(rows, strings.Repeat("─", 46))

	for i, svc := range m.services {
		statusColor := theme.Current.Muted
		if svc.Active == "active" {
			statusColor = theme.Current.Success
		} else if svc.Active == "failed" {
			statusColor = theme.Current.Error
		}

		enabledColor := theme.Current.Muted
		if svc.Enabled == "enabled" {
			enabledColor = theme.Current.Success
		}

		name := fmt.Sprintf("%-20s", truncate(svc.Name, 20))
		status := lipgloss.NewStyle().Foreground(lipgloss.Color(statusColor)).Render(fmt.Sprintf("%-12s", svc.Active))
		enabled := lipgloss.NewStyle().Foreground(lipgloss.Color(enabledColor)).Render(fmt.Sprintf("%-12s", svc.Enabled))

		row := name + status + enabled

		if i == m.cursor {
			cursor := theme.MenuCursorStyle()
			row = cursor.Render("> ") + theme.MenuSelectedStyle().Render(row)
		} else {
			row = "  " + theme.MenuItemStyle().Render(row)
		}
		rows = append(rows, row)
	}

	table := strings.Join(rows, "\n")

	tableBlock := lipgloss.NewStyle().
		Width(width).
		Align(lipgloss.Center).
		Render(table)

	return lipgloss.JoinVertical(lipgloss.Left,
		"",
		tableBlock,
	)
}

func (m ServiceListModel) Title() string {
	if m.showAll {
		return "All Services"
	}
	return "Common Services"
}

func (m ServiceListModel) ShortHelp() []string {
	return []string{"j/k navigate", "enter select"}
}

func truncate(s string, max int) string {
	if len(s) <= max {
		return s
	}
	return s[:max-1] + "…"
}
