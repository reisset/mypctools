package services

import (
	"fmt"
	"strings"

	"github.com/charmbracelet/bubbles/viewport"
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

	return menuBlock
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
	viewport viewport.Model
}

// servicesLoadedMsg is sent when service list is loaded.
type servicesLoadedMsg struct {
	services []system.ServiceStatus
}

// NewServiceList creates a new service list screen.
func NewServiceList(shared *state.Shared, showAll bool) ServiceListModel {
	// Initialize viewport with current terminal size (will be resized on WindowSizeMsg)
	width := shared.TerminalWidth
	height := shared.TerminalHeight
	if width == 0 {
		width = 80
	}
	if height == 0 {
		height = 24
	}
	vp := viewport.New(width, height-6)
	return ServiceListModel{
		shared:   shared,
		showAll:  showAll,
		loading:  true,
		viewport: vp,
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
	case tea.WindowSizeMsg:
		headerHeight := 6 // header + separator + padding + footer
		m.viewport = viewport.New(msg.Width, msg.Height-headerHeight)
		m.viewport.SetContent(m.renderRows())
		return m, nil

	case servicesLoadedMsg:
		m.services = msg.services
		m.loading = false
		m.viewport.SetContent(m.renderRows())
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
			m.scrollToCursor()
			m.viewport.SetContent(m.renderRows())
		case "k", "up":
			m.cursor--
			if m.cursor < 0 {
				m.cursor = len(m.services) - 1
			}
			m.scrollToCursor()
			m.viewport.SetContent(m.renderRows())
		case "enter", " ":
			if len(m.services) > 0 && m.cursor < len(m.services) {
				return m, app.Navigate(NewServiceDetail(m.shared, m.services[m.cursor].Name))
			}
		}
	}
	return m, nil
}

// scrollToCursor adjusts viewport offset to keep cursor visible.
func (m *ServiceListModel) scrollToCursor() {
	visibleHeight := m.viewport.Height
	if visibleHeight <= 0 {
		return
	}

	topLine := m.viewport.YOffset
	bottomLine := topLine + visibleHeight - 1

	if m.cursor < topLine {
		m.viewport.SetYOffset(m.cursor)
	} else if m.cursor > bottomLine {
		m.viewport.SetYOffset(m.cursor - visibleHeight + 1)
	}
}

// renderRows builds the table content for the viewport.
func (m ServiceListModel) renderRows() string {
	if len(m.services) == 0 {
		return ""
	}

	var rows []string
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

	return strings.Join(rows, "\n")
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

	// Table header (fixed, not scrolled)
	header := fmt.Sprintf("%-20s %-12s %-12s", "Service", "Status", "Enabled")
	headerStyle := lipgloss.NewStyle().
		Foreground(lipgloss.Color(theme.Current.Muted)).
		Bold(true)
	headerLine := headerStyle.Render(header)
	separator := strings.Repeat("─", 46)

	// Scroll indicator
	scrollInfo := ""
	if len(m.services) > m.viewport.Height {
		scrollInfo = theme.MutedStyle().Render(fmt.Sprintf(" [%d/%d]", m.cursor+1, len(m.services)))
	}

	headerBlock := lipgloss.NewStyle().
		Width(width).
		Align(lipgloss.Center).
		Render(headerLine + scrollInfo + "\n" + separator)

	// Viewport content (scrollable)
	viewportBlock := lipgloss.NewStyle().
		Width(width).
		Align(lipgloss.Center).
		Render(m.viewport.View())

	return lipgloss.JoinVertical(lipgloss.Left,
		"",
		headerBlock,
		viewportBlock,
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
