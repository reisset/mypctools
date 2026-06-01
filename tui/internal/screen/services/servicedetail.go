package services

import (
	"fmt"
	"strings"

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

type execDoneMsg struct {
	err error
}

// ServiceDetailModel shows stats and actions for a single service.
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

func buildMenuItems(status system.ServiceStatus) []actionItem {
	var items []actionItem
	if status.Active == "active" {
		items = append(items, actionItem{icon: "■", label: "Stop", action: actionStop})
	} else {
		items = append(items, actionItem{icon: "▶", label: "Start", action: actionStart})
	}
	items = append(items, actionItem{icon: "⟳", label: "Restart", action: actionRestart})
	if status.Enabled == "enabled" {
		items = append(items, actionItem{icon: "○", label: "Disable", action: actionDisable})
	} else {
		items = append(items, actionItem{icon: "●", label: "Enable", action: actionEnable})
	}
	items = append(items, actionItem{icon: "←", label: "Back", action: actionBack})
	return items
}

func (m ServiceDetailModel) Init() tea.Cmd { return nil }

func (m ServiceDetailModel) Update(msg tea.Msg) (app.Screen, tea.Cmd) {
	switch msg := msg.(type) {
	case execDoneMsg:
		m.actionDone = true
		m.actionErr = msg.err
		m.logServiceAction()
		m.status = system.GetServiceStatus(m.serviceName)
		m.items = buildMenuItems(m.status)
		if m.cursor >= len(m.items) {
			m.cursor = len(m.items) - 1
		}
		return m, nil

	case tea.KeyMsg:
		if m.actionDone {
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
	case actionStart:
		cmd := system.ServiceActionCmd(m.serviceName, "start")
		return tea.ExecProcess(cmd, func(err error) tea.Msg { return execDoneMsg{err: err} })
	case actionStop:
		cmd := system.ServiceActionCmd(m.serviceName, "stop")
		return tea.ExecProcess(cmd, func(err error) tea.Msg { return execDoneMsg{err: err} })
	case actionRestart:
		cmd := system.ServiceActionCmd(m.serviceName, "restart")
		return tea.ExecProcess(cmd, func(err error) tea.Msg { return execDoneMsg{err: err} })
	case actionEnable:
		cmd := system.ServiceActionCmd(m.serviceName, "enable")
		return tea.ExecProcess(cmd, func(err error) tea.Msg { return execDoneMsg{err: err} })
	case actionDisable:
		cmd := system.ServiceActionCmd(m.serviceName, "disable")
		return tea.ExecProcess(cmd, func(err error) tea.Msg { return execDoneMsg{err: err} })
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

	muted := theme.MutedStyle()
	sep := "  " + theme.HelpDividerStyle().Render(strings.Repeat("─", 40))

	// Status row
	var activeStr string
	if m.status.Active == "active" {
		activeStr = theme.SuccessStyle().Render("● active")
	} else {
		activeStr = theme.ErrorStyle().Render("○ " + m.status.Active)
	}

	var enabledStr string
	if m.status.Enabled == "enabled" {
		enabledStr = theme.SuccessStyle().Render("yes")
	} else {
		enabledStr = muted.Render(m.status.Enabled)
	}

	col := func(label, value string) string {
		return lipgloss.JoinVertical(lipgloss.Left,
			muted.Render(label),
			value,
		)
	}

	pidStr := muted.Render("—")
	if m.status.PID != "" {
		pidStr = muted.Render(m.status.PID)
	}

	statusRow := lipgloss.JoinHorizontal(lipgloss.Top,
		lipgloss.NewStyle().Width(20).Render(col("STATUS", activeStr)),
		lipgloss.NewStyle().Width(20).Render(col("ENABLED", enabledStr)),
		lipgloss.NewStyle().Width(16).Render(col("PID", pidStr)),
	)

	statsBlock := lipgloss.NewStyle().Width(width).PaddingLeft(2).Render(statusRow)

	// Action result
	var resultBlock string
	if m.actionDone {
		var line string
		if m.actionErr != nil {
			line = theme.ErrorStyle().Render(fmt.Sprintf("Error: %v", m.actionErr))
		} else {
			line = theme.SuccessStyle().Render("✓ Action completed")
		}
		resultBlock = lipgloss.NewStyle().Width(width).Align(lipgloss.Center).Render(line) +
			"\n" + lipgloss.NewStyle().Width(width).Align(lipgloss.Center).Render(muted.Render("press any key to continue"))
	}

	// Action menu — insert separator before the last item (Back)
	listItems := make([]ui.ListItem, 0, len(m.items)+1)
	for i, item := range m.items {
		if i == len(m.items)-1 {
			listItems = append(listItems, ui.ListItem{Separator: true})
		}
		listItems = append(listItems, ui.ListItem{Icon: item.icon, Label: item.label})
	}

	// Shift cursor past separator (separator is before last item, Back).
	listCursor := m.cursor
	if m.cursor == len(m.items)-1 {
		listCursor = m.cursor + 1
	}
	menu := ui.RenderList(listItems, listCursor, ui.ListConfig{
		Width:         48,
		MaxInnerWidth: 48,
	})
	menuBlock := lipgloss.NewStyle().Width(width).PaddingLeft(2).Render(menu)

	parts := []string{"", statsBlock, sep}
	if resultBlock != "" {
		parts = append(parts, resultBlock)
	}
	parts = append(parts, "", menuBlock)
	return lipgloss.JoinVertical(lipgloss.Left, parts...)
}

func (m ServiceDetailModel) Title() string      { return m.serviceName }
func (m ServiceDetailModel) HandlesBack() bool  { return false }

func (m ServiceDetailModel) ShortHelp() []string {
	if m.actionDone {
		return []string{"any key continue"}
	}
	return []string{"enter confirm"}
}
