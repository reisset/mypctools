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
}

// NewServiceDetail creates a new service detail screen.
func NewServiceDetail(shared *state.Shared, serviceName string) ServiceDetailModel {
	items := []actionItem{
		{label: "Start", action: actionStart},
		{label: "Stop", action: actionStop},
		{label: "Restart", action: actionRestart},
		{label: "Enable", action: actionEnable},
		{label: "Disable", action: actionDisable},
		{label: "View Status", action: actionViewStatus},
		{label: theme.Icons.Back + "  Back", action: actionBack},
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

func (m ServiceDetailModel) View() string {
	width := m.shared.TerminalWidth
	if width == 0 {
		width = 80
	}

	// Title
	title := lipgloss.NewStyle().
		Foreground(lipgloss.Color(theme.Current.Primary)).
		Bold(true).
		Render("Service: " + m.serviceName)

	titleBlock := lipgloss.NewStyle().
		Width(width).
		Align(lipgloss.Center).
		Render(title)

	// Status info
	statusColor := theme.Current.Muted
	if m.status.Active == "active" {
		statusColor = theme.Current.Success
	} else if m.status.Active == "failed" {
		statusColor = theme.Current.Error
	}

	enabledColor := theme.Current.Muted
	if m.status.Enabled == "enabled" {
		enabledColor = theme.Current.Success
	}

	statusLine := fmt.Sprintf("Status: %s   Enabled: %s",
		lipgloss.NewStyle().Foreground(lipgloss.Color(statusColor)).Render(m.status.Active),
		lipgloss.NewStyle().Foreground(lipgloss.Color(enabledColor)).Render(m.status.Enabled),
	)

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
			resultLine = theme.SuccessStyle().Render("Action completed successfully")
		}
		prompt := theme.MutedStyle().Render("Press any key to continue...")
		resultBlock = lipgloss.NewStyle().
			Width(width).
			Align(lipgloss.Center).
			Render(resultLine+"\n"+prompt) + "\n"
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
	return []string{"j/k navigate", "enter select"}
}
