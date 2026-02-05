package exec

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/reisset/mypctools/tui/internal/app"
	"github.com/reisset/mypctools/tui/internal/bundle"
	"github.com/reisset/mypctools/tui/internal/logging"
	"github.com/reisset/mypctools/tui/internal/state"
	"github.com/reisset/mypctools/tui/internal/system"
	"github.com/reisset/mypctools/tui/internal/theme"
)

// execDoneMsg is sent when the script finishes.
type execDoneMsg struct {
	err error
}

// Model handles script execution with full terminal control.
type Model struct {
	shared  *state.Shared
	bundle  bundle.Bundle
	action  string // "install" or "uninstall"
	done    bool
	err     error
	started bool
}

// New creates an exec screen for the given bundle and action.
func New(shared *state.Shared, b bundle.Bundle, action string) Model {
	return Model{
		shared: shared,
		bundle: b,
		action: action,
	}
}

func (m Model) Init() tea.Cmd {
	// Build script path
	scriptPath := filepath.Join(m.shared.RootDir, "scripts", m.bundle.ID, m.action+".sh")

	// Use tea.ExecProcess to give the script full terminal control
	cmd := exec.Command("bash", scriptPath)
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
			if err := logging.LogAction(fmt.Sprintf("Script %s %s failed", m.bundle.Name, m.action)); err != nil {
				fmt.Fprintf(os.Stderr, "logging failed: %v\n", err)
			}
		} else {
			if err := logging.LogAction(fmt.Sprintf("Script %s %s completed", m.bundle.Name, m.action)); err != nil {
				fmt.Fprintf(os.Stderr, "logging failed: %v\n", err)
			}
			system.Notify("mypctools", fmt.Sprintf("%s %s completed", m.bundle.Name, m.action))
		}
		return m, nil

	case tea.KeyMsg:
		if m.done {
			// Any key returns to the script menu
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
			statusLine = theme.ErrorStyle().Render(fmt.Sprintf("Failed: %v", m.err))
		} else {
			statusLine = theme.SuccessStyle().Render(fmt.Sprintf("%s completed successfully", m.action))
		}

		prompt := theme.MutedStyle().Render("Press any key to continue...")

		content = lipgloss.JoinVertical(lipgloss.Center,
			"",
			statusLine,
			"",
			prompt,
		)
	} else {
		content = theme.MutedStyle().Render(fmt.Sprintf("Running %s for %s...", m.action, m.bundle.Name))
	}

	return lipgloss.NewStyle().
		Width(width).
		Align(lipgloss.Center).
		Render(content)
}

func (m Model) Title() string {
	return fmt.Sprintf("%s %s", m.action, m.bundle.Name)
}

func (m Model) ShortHelp() []string {
	if m.done {
		return []string{"any key continue"}
	}
	return []string{}
}
