package cleanup

import (
	"fmt"
	"strings"

	"github.com/charmbracelet/bubbles/spinner"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/reisset/mypctools/tui/internal/app"
	"github.com/reisset/mypctools/tui/internal/logging"
	"github.com/reisset/mypctools/tui/internal/state"
	"github.com/reisset/mypctools/tui/internal/system"
	"github.com/reisset/mypctools/tui/internal/theme"
	"github.com/reisset/mypctools/tui/internal/ui"
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
	spinner      spinner.Model
}

// New creates a new cleanup screen.
func New(shared *state.Shared) Model {
	s := spinner.New()
	s.Spinner = spinner.Dot
	s.Style = lipgloss.NewStyle().Foreground(lipgloss.Color(theme.Current.Primary))
	return Model{
		shared:  shared,
		phase:   phasePackageCleanup,
		cursor:  actionYes,
		spinner: s,
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
	// Forward spinner ticks during cache-clearing phase
	if m.phase == phaseClearingCache {
		var cmd tea.Cmd
		m.spinner, cmd = m.spinner.Update(msg)
		// Check for completion message first, then return spinner cmd
		switch msg := msg.(type) {
		case cacheClearDoneMsg:
			m.cacheErr = msg.err
			m.cacheCleared = true
			m.phase = phaseDone
			m.logAndNotify()
			if m.pkgErr == nil && m.cacheErr == nil {
				return m, app.Toast(theme.Icons.Check+" System cleanup completed", false)
			}
			return m, nil
		default:
			_ = msg
		}
		return m, cmd
	}

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
		if m.pkgErr == nil && m.cacheErr == nil {
			return m, app.Toast(theme.Icons.Check+" System cleanup completed", false)
		}
		return m, nil

	case tea.KeyMsg:
		switch m.phase {
		case phaseAskUserCache:
			switch msg.String() {
			case "down", "up", "tab", "j", "k":
				if m.cursor == actionYes {
					m.cursor = actionNo
				} else {
					m.cursor = actionYes
				}
			case "enter", " ":
				if m.cursor == actionYes {
					m.phase = phaseClearingCache
					return m, tea.Batch(m.spinner.Tick, m.clearCaches())
				}
				m.phase = phaseDone
				m.logAndNotify()
				if m.pkgErr == nil {
					return m, app.Toast(theme.Icons.Check+" System cleanup completed", false)
				}
				return m, nil
			case "y":
				m.phase = phaseClearingCache
				return m, tea.Batch(m.spinner.Tick, m.clearCaches())
			case "n":
				m.phase = phaseDone
				m.logAndNotify()
				if m.pkgErr == nil {
					return m, app.Toast(theme.Icons.Check+" System cleanup completed", false)
				}
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
			pkgStatus = theme.SuccessStyle().Render(theme.Icons.Check + " Package cleanup completed")
		}

		pkgStatusBlock := lipgloss.NewStyle().
			Width(width).
			Align(lipgloss.Center).
			Render(pkgStatus)

		// Question
		question := theme.SubheaderStyle().Render("Clear user caches (thumbnails, trash)?")
		questionBlock := lipgloss.NewStyle().
			Width(width).
			Align(lipgloss.Center).
			Render(question)

		// Action buttons using list component
		items := []ui.ListItem{
			{Icon: theme.Icons.Check, Label: "Yes"},
			{Icon: theme.Icons.Back, Label: "No"},
		}
		cursor := 0
		if m.cursor == actionNo {
			cursor = 1
		}

		buttons := ui.RenderList(items, cursor, ui.ListConfig{
			Width:         width,
			ShowCursor:    true,
			HighlightFull: true,
		})

		buttonsBlock := lipgloss.NewStyle().
			Width(width).
			Align(lipgloss.Center).
			Render(buttons)

		content = lipgloss.JoinVertical(lipgloss.Left,
			pkgStatusBlock,
			"",
			questionBlock,
			"",
			buttonsBlock,
		)

	case phaseClearingCache:
		content = m.spinner.View() + " Clearing user caches..."

	case phaseDone:
		var lines []string

		// Package cleanup result
		if m.pkgErr != nil {
			lines = append(lines, theme.WarningStyle().Render(fmt.Sprintf("Package cleanup: had issues (%v)", m.pkgErr)))
		} else {
			lines = append(lines, theme.SuccessStyle().Render(theme.Icons.Check+" Package cleanup: completed"))
		}

		// Cache cleanup result
		if m.cacheCleared {
			if m.cacheErr != nil {
				lines = append(lines, theme.WarningStyle().Render(fmt.Sprintf("User caches: had issues (%v)", m.cacheErr)))
			} else {
				lines = append(lines, theme.SuccessStyle().Render(theme.Icons.Check+" User caches: cleared"))
			}
		} else {
			lines = append(lines, theme.MutedStyle().Render("User caches: skipped"))
		}

		summary := strings.Join(lines, "\n")
		summaryBlock := lipgloss.NewStyle().
			Width(width).
			Align(lipgloss.Center).
			Render(summary)

		title := theme.SubheaderStyle().Render("Cleanup Complete")
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
		return []string{"y yes", "n no"}
	default:
		return []string{}
	}
}
