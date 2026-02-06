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
	status := system.GetServiceStatus(serviceName)

	return ServiceDetailModel{
		shared:      shared,
		serviceName: serviceName,
		status:      status,
		items:       buildMenuItems(status),
		cursor:      0,
	}
}

// buildMenuItems creates context-aware menu items based on service state.
func buildMenuItems(status system.ServiceStatus) []actionItem {
	var items []actionItem

	// Running toggle: show Start if stopped, Stop if running
	if status.Active == "active" {
		items = append(items, actionItem{icon: theme.Icons.Cleanup, label: "Stop", action: actionStop})
	} else {
		items = append(items, actionItem{icon: theme.Icons.Update, label: "Start", action: actionStart})
	}

	// Restart always available
	items = append(items, actionItem{icon: theme.Icons.Update, label: "Restart", action: actionRestart})

	// Boot toggle: show Disable if enabled, Enable if disabled
	if status.Enabled == "enabled" {
		items = append(items, actionItem{icon: theme.Icons.Cleanup, label: "Disable", action: actionDisable})
	} else {
		items = append(items, actionItem{icon: theme.Icons.Check, label: "Enable", action: actionEnable})
	}

	// Back
	items = append(items, actionItem{icon: theme.Icons.Back, label: "Back", action: actionBack})

	return items
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
		// Refresh status and rebuild menu items
		m.status = system.GetServiceStatus(m.serviceName)
		m.items = buildMenuItems(m.status)
		// Reset cursor if it's now out of bounds
		if m.cursor >= len(m.items) {
			m.cursor = len(m.items) - 1
		}
		return m, nil

	case tea.KeyMsg:
		if m.actionDone {
			// Any key clears the action done state
			m.actionDone = false
			m.actionErr = nil
			return m, nil
		}

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
	var actionName string
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
	if m.actionDone {
		return []string{"any key continue"}
	}
	return []string{"enter select"}
}
