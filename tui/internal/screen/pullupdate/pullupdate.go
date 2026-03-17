package pullupdate

import (
	"fmt"
	"os/exec"
	"strings"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/reisset/mypctools/tui/internal/app"
	"github.com/reisset/mypctools/tui/internal/bundle"
	"github.com/reisset/mypctools/tui/internal/state"
	"github.com/reisset/mypctools/tui/internal/theme"
)

// execDoneMsg is sent when git pull finishes.
type execDoneMsg struct {
	err error
}

// syncDoneMsg is sent when config bundle syncing finishes.
type syncDoneMsg struct {
	synced []string
}

// Model handles pulling updates from the remote repository.
type Model struct {
	shared  *state.Shared
	syncing bool
	done    bool
	err     error
	synced  []string
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
		if msg.err != nil {
			m.done = true
			m.err = msg.err
			return m, nil
		}
		m.syncing = true
		return m, func() tea.Msg {
			synced := bundle.SyncInstalled(m.shared.RootDir)
			return syncDoneMsg{synced: synced}
		}

	case syncDoneMsg:
		m.done = true
		m.syncing = false
		m.synced = msg.synced
		toastText := theme.Icons.Check + " Updated!"
		if len(msg.synced) > 0 {
			toastText += fmt.Sprintf(" Synced: %s.", strings.Join(msg.synced, ", "))
		}
		toastText += " Restart mypctools."
		return m, tea.Batch(
			func() tea.Msg { return state.UpdateCountMsg{Count: 0} },
			app.Toast(toastText, false),
		)

	case tea.KeyMsg:
		if m.done {
			// Only reached on error
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
			line := theme.Icons.Check + " Updated!"
			if len(m.synced) > 0 {
				line += fmt.Sprintf(" Synced: %s.", strings.Join(m.synced, ", "))
			}
			statusLine = theme.SuccessStyle().Render(line)
		}

		prompt := theme.MutedStyle().Render("Press any key to continue...")

		content = lipgloss.JoinVertical(lipgloss.Center,
			"",
			statusLine,
			"",
			prompt,
		)
	} else if m.syncing {
		content = theme.MutedStyle().Render("Syncing configs...")
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
