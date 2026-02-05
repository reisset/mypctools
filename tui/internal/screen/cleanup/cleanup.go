package cleanup

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
)

type phase int

const (
	phasePackageCleanup phase = iota
	phaseAskUserCache
	phaseClearingCache
	phaseDone
)

// execDoneMsg is sent when a command finishes.
type execDoneMsg struct {
	err error
}

// cacheClearDoneMsg is sent when cache clearing finishes.
type cacheClearDoneMsg struct {
	err error
}

type action int

const (
	actionYes action = iota
	actionNo
)

// Model handles the system cleanup screen.
type Model struct {
	shared       *state.Shared
	phase        phase
	cursor       action
	pkgErr       error
	cacheCleared bool
	cacheErr     error
}

// New creates a new cleanup screen.
func New(shared *state.Shared) Model {
	return Model{
		shared: shared,
		phase:  phasePackageCleanup,
		cursor: actionYes,
	}
}

func (m Model) Init() tea.Cmd {
	cmd := system.CleanupCommand(m.shared.Distro.Type)
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
		m.pkgErr = msg.err
		m.phase = phaseAskUserCache
		return m, nil

	case cacheClearDoneMsg:
		m.cacheErr = msg.err
		m.cacheCleared = true
		m.phase = phaseDone
		m.logAndNotify()
		return m, nil

	case tea.KeyMsg:
		switch m.phase {
		case phaseAskUserCache:
			switch msg.String() {
			case "j", "down", "k", "up", "tab":
				if m.cursor == actionYes {
					m.cursor = actionNo
				} else {
					m.cursor = actionYes
				}
			case "enter", " ":
				if m.cursor == actionYes {
					m.phase = phaseClearingCache
					return m, m.clearCaches()
				}
				m.phase = phaseDone
				m.logAndNotify()
				return m, nil
			case "y":
				m.phase = phaseClearingCache
				return m, m.clearCaches()
			case "n":
				m.phase = phaseDone
				m.logAndNotify()
				return m, nil
			}
		case phaseDone:
			return m, app.PopScreen()
		}
	}
	return m, nil
}

func (m Model) clearCaches() tea.Cmd {
	return func() tea.Msg {
		err := system.ClearUserCaches()
		return cacheClearDoneMsg{err: err}
	}
}

func (m Model) logAndNotify() {
	if m.pkgErr != nil {
		logging.LogAction("System cleanup completed with errors")
	} else {
		logging.LogAction("System cleanup completed")
	}
	system.Notify("mypctools", "System cleanup completed")
}

func (m Model) View() string {
	width := m.shared.TerminalWidth
	if width == 0 {
		width = 80
	}

	var content string

	switch m.phase {
	case phasePackageCleanup:
		content = theme.MutedStyle().Render("Running package cleanup...")

	case phaseAskUserCache:
		// Show package cleanup result
		var pkgStatus string
		if m.pkgErr != nil {
			pkgStatus = theme.WarningStyle().Render(fmt.Sprintf("Package cleanup had issues: %v", m.pkgErr))
		} else {
			pkgStatus = theme.SuccessStyle().Render("Package cleanup completed")
		}

		pkgStatusBlock := lipgloss.NewStyle().
			Width(width).
			Align(lipgloss.Center).
			Render(pkgStatus)

		// Question
		question := theme.PrimaryStyle().Bold(true).Render("Clear user caches (thumbnails, trash)?")
		questionBlock := lipgloss.NewStyle().
			Width(width).
			Align(lipgloss.Center).
			Render(question)

		// Action buttons
		var yesBtn, noBtn string
		cursor := theme.MenuCursorStyle()
		normal := theme.MenuItemStyle()
		selected := theme.MenuSelectedStyle()

		if m.cursor == actionYes {
			yesBtn = cursor.Render("> ") + selected.Render("Yes")
			noBtn = "  " + normal.Render("No")
		} else {
			yesBtn = "  " + normal.Render("Yes")
			noBtn = cursor.Render("> ") + selected.Render("No")
		}

		buttonsBlock := lipgloss.NewStyle().
			Width(width).
			Align(lipgloss.Center).
			Render(yesBtn + "\n" + noBtn)

		content = lipgloss.JoinVertical(lipgloss.Left,
			pkgStatusBlock,
			"",
			questionBlock,
			"",
			buttonsBlock,
		)

	case phaseClearingCache:
		content = theme.MutedStyle().Render("Clearing user caches...")

	case phaseDone:
		var lines []string

		// Package cleanup result
		if m.pkgErr != nil {
			lines = append(lines, theme.WarningStyle().Render(fmt.Sprintf("Package cleanup: had issues (%v)", m.pkgErr)))
		} else {
			lines = append(lines, theme.SuccessStyle().Render("Package cleanup: completed"))
		}

		// Cache cleanup result
		if m.cacheCleared {
			if m.cacheErr != nil {
				lines = append(lines, theme.WarningStyle().Render(fmt.Sprintf("User caches: had issues (%v)", m.cacheErr)))
			} else {
				lines = append(lines, theme.SuccessStyle().Render("User caches: cleared"))
			}
		} else {
			lines = append(lines, theme.MutedStyle().Render("User caches: skipped"))
		}

		summary := strings.Join(lines, "\n")
		summaryBlock := lipgloss.NewStyle().
			Width(width).
			Align(lipgloss.Center).
			Render(summary)

		title := lipgloss.NewStyle().
			Foreground(lipgloss.Color(theme.Current.Primary)).
			Bold(true).
			Render("Cleanup Complete")

		titleBlock := lipgloss.NewStyle().
			Width(width).
			Align(lipgloss.Center).
			Render(title)

		prompt := theme.MutedStyle().Render("Press any key to continue...")
		promptBlock := lipgloss.NewStyle().
			Width(width).
			Align(lipgloss.Center).
			Render(prompt)

		content = lipgloss.JoinVertical(lipgloss.Left,
			"",
			titleBlock,
			"",
			summaryBlock,
			"",
			promptBlock,
		)
	}

	return lipgloss.NewStyle().
		Width(width).
		Align(lipgloss.Center).
		Render(content)
}

func (m Model) Title() string {
	return "System Cleanup"
}

func (m Model) ShortHelp() []string {
	switch m.phase {
	case phaseAskUserCache:
		return []string{"j/k navigate", "enter select", "y yes", "n no"}
	case phaseDone:
		return []string{"any key continue"}
	default:
		return []string{}
	}
}
