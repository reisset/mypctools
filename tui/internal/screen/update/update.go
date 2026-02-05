package update

import (
	"fmt"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/reisset/mypctools/tui/internal/app"
	"github.com/reisset/mypctools/tui/internal/logging"
	"github.com/reisset/mypctools/tui/internal/state"
	"github.com/reisset/mypctools/tui/internal/system"
	"github.com/reisset/mypctools/tui/internal/theme"
)

// execDoneMsg is sent when the update finishes.
type execDoneMsg struct {
	err error
}

// Model handles the full system update screen.
type Model struct {
	shared *state.Shared
	done   bool
	err    error
}

// New creates a new update screen.
func New(shared *state.Shared) Model {
	return Model{
		shared: shared,
	}
}

func (m Model) Init() tea.Cmd {
	cmd := system.UpdateCommand(m.shared.Distro.Type)
	if cmd == nil {
		return func() tea.Msg {
			return execDoneMsg{err: fmt.Errorf("unsupported distro: %s", m.shared.Distro.Type)}
		}
	}

	return tea.ExecProcess(cmd, func(err error) tea.Msg {
		return execDoneMsg{err: err}
	})
}

func (m Model) Update(msg tea.Msg) (app.Screen, tea.Cmd) {
	switch msg := msg.(type) {
	case execDoneMsg:
		m.done = true
		m.err = msg.err
		if msg.err != nil {
			logging.LogAction("System update failed")
		} else {
			logging.LogAction("System update completed")
			system.Notify("mypctools", "System update completed")
		}
		return m, nil

	case tea.KeyMsg:
		if m.done {
			return m, app.PopScreen()
		}
	}
	return m, nil
}

func (m Model) View() string {
	width := m.shared.TerminalWidth
	if width == 0 {
		width = 80
	}

	var content string

	if m.done {
		var statusLine string
		if m.err != nil {
			statusLine = theme.ErrorStyle().Render(fmt.Sprintf("Update failed: %v", m.err))
		} else {
			statusLine = theme.SuccessStyle().Render(theme.Icons.Check + " System update completed successfully")
		}

		prompt := theme.MutedStyle().Render("Press any key to continue...")

		content = lipgloss.JoinVertical(lipgloss.Center,
			"",
			statusLine,
			"",
			prompt,
		)
	} else {
		content = theme.MutedStyle().Render("Running system update...")
	}

	return lipgloss.NewStyle().
		Width(width).
		Align(lipgloss.Center).
		Render(content)
}

func (m Model) Title() string {
	return "Full System Update"
}

func (m Model) ShortHelp() []string {
	if m.done {
		return []string{"any key continue"}
	}
	return []string{}
}
