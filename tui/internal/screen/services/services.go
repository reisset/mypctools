package services

import (
	"fmt"
	"strings"
	"unicode/utf8"

	"github.com/charmbracelet/bubbles/viewport"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/reisset/mypctools/tui/internal/app"
	"github.com/reisset/mypctools/tui/internal/state"
	"github.com/reisset/mypctools/tui/internal/system"
	"github.com/reisset/mypctools/tui/internal/theme"
	"github.com/reisset/mypctools/tui/internal/ui"
)

type menuItem struct {
	icon  string
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
		{icon: theme.Icons.Service, label: "Common Services", id: "common"},
		{icon: theme.Icons.Info, label: "All Services", id: "all"},
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
		case "up", "k":
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

	return menuBlock
}

func (m Model) Title() string {
	return "Service Manager"
}

func (m Model) ShortHelp() []string {
	return []string{"enter select"}
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
		case "down", "j":
			m.cursor++
			if m.cursor >= len(m.services) {
				m.cursor = 0
			}
			m.scrollToCursor()
			m.viewport.SetContent(m.renderRows())
		case "up", "k":
			m.cursor--
			if m.cursor < 0 {
				m.cursor = len(m.services) - 1
			}
			m.scrollToCursor()
			m.viewport.SetContent(m.renderRows())
		case "enter", " ":
			if len(m.services) > 0 && m.cursor >= 0 && m.cursor < len(m.services) {
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

// renderRows builds the table content for the viewport with enhanced styling.
func (m ServiceListModel) renderRows() string {
	if len(m.services) == 0 {
		return ""
	}

	var rows []string
	for i, svc := range m.services {
		// Format service name
		name := fmt.Sprintf("%-20s", truncate(svc.Name, 20))

		// Status badge with colors - use lipgloss.Width for ANSI-aware padding
		status := ui.StatusBadge(svc.Active)
		statusWidth := lipgloss.Width(status)
		if statusWidth < 12 {
			status = status + strings.Repeat(" ", 12-statusWidth)
		}

		// Enabled badge - use lipgloss.Width for ANSI-aware padding
		enabled := ui.EnabledBadge(svc.Enabled)
		enabledWidth := lipgloss.Width(enabled)
		if enabledWidth < 10 {
			enabled = enabled + strings.Repeat(" ", 10-enabledWidth)
		}

		row := name + "  " + status + "  " + enabled

		if i == m.cursor {
			// Full-width highlight for selected row
			row = theme.TableRowSelectedStyle().Render(theme.Icons.Cursor + " " + row)
		} else {
			row = "  " + theme.TableRowStyle().Render(row)
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

	// Table header with styling
	header := fmt.Sprintf("%-20s  %-12s  %-10s", "Service", "Status", "Enabled")
	headerLine := theme.TableHeaderStyle().Render(header)

	// Separator using theme color
	separator := theme.HelpDividerStyle().Render(strings.Repeat("─", 48))

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
	return []string{"enter details"}
}

func truncate(s string, max int) string {
	if utf8.RuneCountInString(s) <= max {
		return s
	}
	runes := []rune(s)
	return string(runes[:max-1]) + "…"
}
