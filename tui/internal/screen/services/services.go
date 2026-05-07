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

func New(shared *state.Shared) Model {
	items := []menuItem{
		{icon: "◎", label: "Common Services", id: "common"},
		{icon: "◎", label: "All Services", id: "all"},
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

	// Build list: separator before last item (Back).
	listItems := make([]ui.ListItem, 0, len(m.items)+1)
	for i, item := range m.items {
		if i == len(m.items)-1 {
			listItems = append(listItems, ui.ListItem{Separator: true})
		}
		listItems = append(listItems, ui.ListItem{Icon: item.icon, Label: item.label})
	}
	listCursor := m.cursor
	if m.cursor == len(m.items)-1 {
		listCursor = m.cursor + 1
	}
	menu := ui.RenderList(listItems, listCursor, ui.ListConfig{
		Width:         50,
		MaxInnerWidth: 50,
	})

	return lipgloss.NewStyle().
		Width(width).
		Align(lipgloss.Center).
		Render(menu)
}

func (m Model) Title() string { return "Service Manager" }
func (m Model) ShortHelp() []string {
	return []string{"enter select"}
}

// ─── Service List ───────────────────────────────────────────────────────────

// ServiceListModel shows a list of services with their status.
type ServiceListModel struct {
	shared   *state.Shared
	services []system.ServiceStatus
	cursor   int
	showAll  bool
	loading  bool
	viewport viewport.Model
}

type servicesLoadedMsg struct {
	services []system.ServiceStatus
}

func NewServiceList(shared *state.Shared, showAll bool) ServiceListModel {
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
			var svcs []system.ServiceStatus
			for _, name := range names {
				svcs = append(svcs, system.GetServiceStatus(name))
			}
			return servicesLoadedMsg{services: svcs}
		}
		return servicesLoadedMsg{services: system.GetKnownServices()}
	}
}

func (m ServiceListModel) Update(msg tea.Msg) (app.Screen, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.viewport = viewport.New(msg.Width, msg.Height-6)
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
		case "down":
			m.cursor++
			if m.cursor >= len(m.services) {
				m.cursor = 0
			}
			m.scrollToCursor()
			m.viewport.SetContent(m.renderRows())
		case "up":
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

func (m *ServiceListModel) scrollToCursor() {
	visH := m.viewport.Height
	if visH <= 0 {
		return
	}
	top := m.viewport.YOffset
	bottom := top + visH - 1
	if m.cursor < top {
		m.viewport.SetYOffset(m.cursor)
	} else if m.cursor > bottom {
		m.viewport.SetYOffset(m.cursor - visH + 1)
	}
}

func (m ServiceListModel) renderRows() string {
	if len(m.services) == 0 {
		return ""
	}

	bar := lipgloss.NewStyle().Foreground(lipgloss.Color(theme.Current.Border)).Render("│")
	selectedBg := lipgloss.NewStyle().
		Background(lipgloss.Color(theme.Current.Highlight)).
		Foreground(lipgloss.Color("#ffffff")).
		Bold(true)

	var rows []string
	for i, svc := range m.services {
		name := truncate(svc.Name, 26)
		nameCol := fmt.Sprintf("%-26s", name)

		var statusCol string
		switch svc.Active {
		case "active":
			statusCol = theme.SuccessStyle().Render("● up  ")
		case "inactive":
			statusCol = theme.ErrorStyle().Render("○ down")
		default:
			statusCol = theme.MutedStyle().Render("○ " + truncate(svc.Active, 4))
		}

		row := nameCol + "  " + statusCol

		if i == m.cursor {
			content := selectedBg.Render("  " + row + "  ")
			rows = append(rows, bar+content)
		} else {
			rows = append(rows, "   "+theme.MutedStyle().Render(row))
		}
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
		return lipgloss.NewStyle().Width(width).Align(lipgloss.Center).Render(loading)
	}

	if len(m.services) == 0 {
		msg := theme.WarningStyle().Render("No services found")
		return lipgloss.NewStyle().Width(width).Align(lipgloss.Center).Render(msg)
	}

	// Column header
	header := lipgloss.NewStyle().
		Foreground(lipgloss.Color(theme.Current.Muted)).
		PaddingLeft(3).
		Render(fmt.Sprintf("%-26s  %s", "SERVICE", "STATUS"))

	// Scroll count hint
	var countHint string
	if len(m.services) > m.viewport.Height {
		countHint = "  " + theme.MutedStyle().Render(fmt.Sprintf("[%d/%d]", m.cursor+1, len(m.services)))
	}

	sep := "   " + theme.HelpDividerStyle().Render(strings.Repeat("─", 36))

	return lipgloss.JoinVertical(lipgloss.Left,
		"",
		header+countHint,
		sep,
		m.viewport.View(),
	)
}

func (m ServiceListModel) Title() string {
	label := "Common Services"
	if m.showAll {
		label = "All Services"
	}
	if !m.loading && len(m.services) > 0 {
		return fmt.Sprintf("%s (%d)", label, len(m.services))
	}
	return label
}

func (m ServiceListModel) ShortHelp() []string {
	return []string{"↑↓ navigate", "enter details"}
}

func truncate(s string, max int) string {
	if utf8.RuneCountInString(s) <= max {
		return s
	}
	runes := []rune(s)
	return string(runes[:max-1]) + "…"
}
