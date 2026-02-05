package services

import (
	"fmt"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/reisset/mypctools/tui/internal/app"
	"github.com/reisset/mypctools/tui/internal/logging"
	"github.com/reisset/mypctools/tui/internal/state"
	"github.com/reisset/mypctools/tui/internal/system"
	"github.com/reisset/mypctools/tui/internal/theme"
	"github.com/reisset/mypctools/tui/internal/ui"
)

type detailAction int

const (
	actionStart detailAction = iota
	actionStop
	actionRestart
	actionEnable
	actionDisable
	actionViewStatus
	actionBack
)

type actionItem struct {
	icon   string
	label  string
	action detailAction
}

// execDoneMsg is sent when a service action finishes.
type execDoneMsg struct {
	err error
}

// statusRefreshMsg is sent when status should be refreshed.
type statusRefreshMsg struct {
	status system.ServiceStatus
}

// ServiceDetailModel shows actions for a single service.
type ServiceDetailModel struct {
	shared      *state.Shared
	serviceName string
	status      system.ServiceStatus
	cursor      int
	items       []actionItem
	actionDone  bool
	actionErr   error
	lastAction  detailAction
}

// NewServiceDetail creates a new service detail screen.
func NewServiceDetail(shared *state.Shared, serviceName string) ServiceDetailModel {
	items := []actionItem{
		{icon: theme.Icons.Update, label: "Start", action: actionStart},
		{icon: theme.Icons.Cleanup, label: "Stop", action: actionStop},
		{icon: theme.Icons.Update, label: "Restart", action: actionRestart},
		{icon: theme.Icons.Check, label: "Enable", action: actionEnable},
		{icon: theme.Icons.Cleanup, label: "Disable", action: actionDisable},
		{icon: theme.Icons.Info, label: "View Status", action: actionViewStatus},
		{icon: theme.Icons.Back, label: "Back", action: actionBack},
	}

	return ServiceDetailModel{
		shared:      shared,
		serviceName: serviceName,
		status:      system.GetServiceStatus(serviceName),
		items:       items,
		cursor:      0,
	}
}

func (m ServiceDetailModel) Init() tea.Cmd {
	return nil
}

func (m ServiceDetailModel) Update(msg tea.Msg) (app.Screen, tea.Cmd) {
	switch msg := msg.(type) {
	case execDoneMsg:
		m.actionDone = true
		m.actionErr = msg.err
		// Log the action
		m.logServiceAction()
		// Refresh status
		m.status = system.GetServiceStatus(m.serviceName)
		return m, nil

	case tea.KeyMsg:
		if m.actionDone {
			// Any key clears the action done state
			m.actionDone = false
			m.actionErr = nil
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
			m.lastAction = m.items[m.cursor].action
			return m, m.handleAction(m.items[m.cursor].action)
		}
	}
	return m, nil
}

func (m ServiceDetailModel) handleAction(action detailAction) tea.Cmd {
	switch action {
	case actionBack:
		return app.PopScreen()
	case actionViewStatus:
		cmd := system.ServiceStatusCmd(m.serviceName)
		return tea.ExecProcess(cmd, func(err error) tea.Msg {
			return execDoneMsg{err: err}
		})
	case actionStart:
		cmd := system.ServiceActionCmd(m.serviceName, "start")
		return tea.ExecProcess(cmd, func(err error) tea.Msg {
			return execDoneMsg{err: err}
		})
	case actionStop:
		cmd := system.ServiceActionCmd(m.serviceName, "stop")
		return tea.ExecProcess(cmd, func(err error) tea.Msg {
			return execDoneMsg{err: err}
		})
	case actionRestart:
		cmd := system.ServiceActionCmd(m.serviceName, "restart")
		return tea.ExecProcess(cmd, func(err error) tea.Msg {
			return execDoneMsg{err: err}
		})
	case actionEnable:
		cmd := system.ServiceActionCmd(m.serviceName, "enable")
		return tea.ExecProcess(cmd, func(err error) tea.Msg {
			return execDoneMsg{err: err}
		})
	case actionDisable:
		cmd := system.ServiceActionCmd(m.serviceName, "disable")
		return tea.ExecProcess(cmd, func(err error) tea.Msg {
			return execDoneMsg{err: err}
		})
	}
	return nil
}

func (m ServiceDetailModel) logServiceAction() {
	actionName := ""
	switch m.lastAction {
	case actionStart:
		actionName = "start"
	case actionStop:
		actionName = "stop"
	case actionRestart:
		actionName = "restart"
	case actionEnable:
		actionName = "enable"
	case actionDisable:
		actionName = "disable"
	case actionViewStatus:
		return // Don't log view status
	default:
		return
	}

	if m.actionErr != nil {
		logging.LogAction(fmt.Sprintf("Service %s %s failed", m.serviceName, actionName))
	} else {
		logging.LogAction(fmt.Sprintf("Service %s %s", m.serviceName, actionName))
	}
}

func (m ServiceDetailModel) View() string {
	width := m.shared.TerminalWidth
	if width == 0 {
		width = 80
	}

	// Title
	title := theme.SubheaderStyle().Render("Service: " + m.serviceName)
	titleBlock := lipgloss.NewStyle().
		Width(width).
		Align(lipgloss.Center).
		Render(title)

	// Status info with badges
	statusBadge := ui.StatusBadge(m.status.Active)
	enabledBadge := ui.EnabledBadge(m.status.Enabled)

	statusLine := fmt.Sprintf("Status: %s   Enabled: %s", statusBadge, enabledBadge)

	statusBlock := lipgloss.NewStyle().
		Width(width).
		Align(lipgloss.Center).
		Render(statusLine)

	// Action result if any
	var resultBlock string
	if m.actionDone {
		var resultLine string
		if m.actionErr != nil {
			resultLine = theme.ErrorStyle().Render(fmt.Sprintf("Error: %v", m.actionErr))
		} else {
			resultLine = theme.SuccessStyle().Render(theme.Icons.Check + " Action completed successfully")
		}
		prompt := theme.MutedStyle().Render("Press any key to continue...")
		resultBlock = lipgloss.NewStyle().
			Width(width).
			Align(lipgloss.Center).
			Render(resultLine+"\n"+prompt) + "\n"
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

	return lipgloss.JoinVertical(lipgloss.Left,
		titleBlock,
		"",
		statusBlock,
		"",
		resultBlock,
		menuBlock,
	)
}

func (m ServiceDetailModel) Title() string {
	return m.serviceName
}

func (m ServiceDetailModel) ShortHelp() []string {
	return []string{}
}
