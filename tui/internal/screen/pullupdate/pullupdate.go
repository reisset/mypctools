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
	"github.com/reisset/mypctools/tui/internal/ui"
)

type execDoneMsg struct{ err error }
type syncDoneMsg struct{ synced []string }

// Model handles pulling updates from the remote repository.
type Model struct {
	shared  *state.Shared
	syncing bool
	done    bool
	err     error
	synced  []string
	shimmer ui.Shimmer
	fadeup  ui.FadeUp
}

func New(shared *state.Shared) Model {
	return Model{
		shared:  shared,
		shimmer: ui.Shimmer{Text: "Pulling script changes..."},
	}
}

func (m Model) Init() tea.Cmd {
	cmd := exec.Command("git", "-C", m.shared.RootDir, "pull", "origin", "main")
	return tea.ExecProcess(cmd, func(err error) tea.Msg {
		return execDoneMsg{err: err}
	})
}

func (m Model) Update(msg tea.Msg) (app.Screen, tea.Cmd) {
	// Handle shimmer ticks during syncing.
	if m.syncing {
		if cmd := (&m.shimmer).Update(msg); cmd != nil {
			if done, ok := msg.(syncDoneMsg); ok {
				return m.finishSync(done)
			}
			return m, cmd
		}
		if done, ok := msg.(syncDoneMsg); ok {
			return m.finishSync(done)
		}
		return m, nil
	}

	// Handle fade-up ticks on done screen.
	if m.done {
		if cmd := (&m.fadeup).Update(msg); cmd != nil {
			return m, cmd
		}
	}

	switch msg := msg.(type) {
	case execDoneMsg:
		if msg.err != nil {
			m.done = true
			m.err = msg.err
			return m, nil
		}
		m.syncing = true
		return m, tea.Batch(
			m.shimmer.Tick(),
			func() tea.Msg {
				return syncDoneMsg{synced: bundle.SyncInstalled(m.shared.RootDir)}
			},
		)

	case syncDoneMsg:
		return m.finishSync(msg)

	case tea.KeyMsg:
		if m.done {
			return m, app.PopScreen()
		}
	}
	return m, nil
}

// finishSync transitions to the done state after scripts are synced.
func (m Model) finishSync(msg syncDoneMsg) (app.Screen, tea.Cmd) {
	m.done = true
	m.syncing = false
	m.synced = msg.synced

	var lines []string
	lines = append(lines, theme.SuccessStyle().Render("✓  Scripts pulled"))
	if len(m.synced) > 0 {
		lines = append(lines, theme.SuccessStyle().Render("✓  Auto-synced: "+strings.Join(m.synced, ", ")))
	}
	m.fadeup = ui.FadeUp{Lines: lines, Visible: 0}

	toastText := "✓ Updated!"
	if len(m.synced) > 0 {
		toastText += fmt.Sprintf(" Synced: %s.", strings.Join(m.synced, ", "))
	}
	toastText += " Restart mypctools."

	return m, tea.Batch(
		m.fadeup.Start(),
		func() tea.Msg { return state.UpdateCountMsg{Count: 0} },
		app.Toast(toastText, false),
	)
}

func (m Model) View() string {
	width := m.shared.TerminalWidth
	if width == 0 {
		width = 80
	}

	center := func(s string) string {
		return lipgloss.NewStyle().Width(width).Align(lipgloss.Center).Render(s)
	}
	muted := theme.MutedStyle()

	if m.done && m.err != nil {
		errLine := theme.ErrorStyle().Render("Failed to pull updates")
		prompt := muted.Render("press any key to continue")
		return lipgloss.JoinVertical(lipgloss.Left, "", center(errLine), "", center(prompt))
	}

	if m.done {
		title := lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("#ffffff")).Render("Updates Complete")
		prompt := muted.Render("press any key to continue")
		parts := []string{center(title), ""}
		for _, l := range m.fadeup.VisibleLines() {
			parts = append(parts, "   "+l)
		}
		parts = append(parts, "", center(prompt))
		return lipgloss.JoinVertical(lipgloss.Left, parts...)
	}

	if m.syncing {
		return center(m.shimmer.View())
	}

	return center(muted.Render("Pulling updates from origin/main..."))
}

func (m Model) Title() string { return "Pull Updates" }

func (m Model) ShortHelp() []string {
	if m.done {
		return []string{"any key continue"}
	}
	return []string{}
}
