package pullupdate

import (
	"os/exec"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/reisset/mypctools/tui/internal/app"
	"github.com/reisset/mypctools/tui/internal/state"
	"github.com/reisset/mypctools/tui/internal/theme"
)

// execDoneMsg is sent when git pull finishes.
type execDoneMsg struct {
	err error
}

// Model handles pulling updates from the remote repository.
type Model struct {
	shared *state.Shared
	done   bool
	err    error
}

// New creates a new pull update screen.
func New(shared *state.Shared) Model {
	return Model{
		shared: shared,
	}
}

func (m Model) Init() tea.Cmd {
	cmd := exec.Command("git", "-C", m.shared.RootDir, "pull", "origin", "main")
	return tea.ExecProcess(cmd, func(err error) tea.Msg {
		return execDoneMsg{err: err}
	})
}

func (m Model) Update(msg tea.Msg) (app.Screen, tea.Cmd) {
	switch msg := msg.(type) {
	case execDoneMsg:
		m.done = true
		m.err = msg.err
		if msg.err == nil {
			// Clear update count on success
			return m, func() tea.Msg {
				return state.UpdateCountMsg{Count: 0}
			}
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
			statusLine = theme.ErrorStyle().Render("Failed to pull updates")
		} else {
			statusLine = theme.SuccessStyle().Render("Updated! Restart mypctools to use new version.")
		}

		prompt := theme.MutedStyle().Render("Press any key to continue...")

		content = lipgloss.JoinVertical(lipgloss.Center,
			"",
			statusLine,
			"",
			prompt,
		)
	} else {
		content = theme.MutedStyle().Render("Pulling updates from origin/main...")
	}

	return lipgloss.NewStyle().
		Width(width).
		Align(lipgloss.Center).
		Render(content)
}

func (m Model) Title() string {
	return "Pull Updates"
}

func (m Model) ShortHelp() []string {
	if m.done {
		return []string{"any key continue"}
	}
	return []string{}
}
