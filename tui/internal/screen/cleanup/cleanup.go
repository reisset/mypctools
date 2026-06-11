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
	"github.com/reisset/mypctools/tui/internal/ui"
)

type phase int

const (
	phasePackageCleanup phase = iota
	phaseAskUserCache
	phaseClearingCache
	phaseDone
)

type cacheClearDoneMsg struct{ err error }

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
	shimmer      ui.Shimmer
	fadeup       ui.FadeUp
}

func New(shared *state.Shared) Model {
	return Model{
		shared:  shared,
		phase:   phasePackageCleanup,
		cursor:  actionYes,
		shimmer: ui.Shimmer{Text: "Clearing user caches..."},
	}
}

func (m Model) Init() tea.Cmd {
	cmd := system.CleanupCommand(m.shared.Distro.Type)
	if cmd == nil {
		return func() tea.Msg {
			return app.ExecDoneMsg{Err: fmt.Errorf("unsupported distro: %s", m.shared.Distro.Type)}
		}
	}
	return tea.ExecProcess(cmd, func(err error) tea.Msg {
		return app.ExecDoneMsg{Err: err}
	})
}

func (m Model) Update(msg tea.Msg) (app.Screen, tea.Cmd) {
	// Handle shimmer ticks during cache clearing.
	if m.phase == phaseClearingCache {
		if cmd := (&m.shimmer).Update(msg); cmd != nil {
			if done, ok := msg.(cacheClearDoneMsg); ok {
				return m.finishCacheClean(done)
			}
			return m, cmd
		}
		if done, ok := msg.(cacheClearDoneMsg); ok {
			return m.finishCacheClean(done)
		}
		return m, nil
	}

	// Handle fade-up ticks on done screen.
	if m.phase == phaseDone {
		if cmd := (&m.fadeup).Update(msg); cmd != nil {
			return m, cmd
		}
	}

	switch msg := msg.(type) {
	case app.ExecDoneMsg:
		m.pkgErr = msg.Err
		m.phase = phaseAskUserCache
		return m, nil

	case cacheClearDoneMsg:
		return m.finishCacheClean(msg)

	case tea.KeyMsg:
		switch m.phase {
		case phaseAskUserCache:
			switch msg.String() {
			case "down", "up", "tab":
				if m.cursor == actionYes {
					m.cursor = actionNo
				} else {
					m.cursor = actionYes
				}
			case "enter", " ":
				if m.cursor == actionYes {
					m.phase = phaseClearingCache
					return m, tea.Batch(m.shimmer.Tick(), m.clearCaches())
				}
				return m.skipCache()
			case "y":
				m.phase = phaseClearingCache
				return m, tea.Batch(m.shimmer.Tick(), m.clearCaches())
			case "n":
				return m.skipCache()
			}
		case phaseDone:
			return m, app.PopScreen()
		}
	}
	return m, nil
}

// finishCacheClean transitions to phaseDone after cache clearing completes.
func (m Model) finishCacheClean(msg cacheClearDoneMsg) (app.Screen, tea.Cmd) {
	m.cacheErr = msg.err
	m.cacheCleared = true
	m.phase = phaseDone
	m.logAndNotify()
	m.fadeup = buildFadeup(m.pkgErr, true, m.cacheErr == nil, m.cacheErr)
	return m, tea.Batch(m.fadeup.Start(), m.toastCmd())
}

// skipCache transitions to phaseDone without clearing caches.
func (m Model) skipCache() (app.Screen, tea.Cmd) {
	m.phase = phaseDone
	m.logAndNotify()
	m.fadeup = buildFadeup(m.pkgErr, false, false, nil)
	return m, tea.Batch(m.fadeup.Start(), m.toastCmd())
}

func (m Model) toastCmd() tea.Cmd {
	if m.pkgErr == nil && m.cacheErr == nil {
		return app.Toast("✓ System cleanup completed", false)
	}
	return nil
}

func buildFadeup(pkgErr error, cacheRan, cacheOK bool, cacheErr error) ui.FadeUp {
	var lines []string
	if pkgErr != nil {
		lines = append(lines, theme.WarningStyle().Render("⚠  Package cleanup had issues"))
	} else {
		lines = append(lines, theme.SuccessStyle().Render("✓  Package cleanup"))
	}
	if cacheRan {
		if cacheOK {
			lines = append(lines, theme.SuccessStyle().Render("✓  User caches cleared"))
		} else {
			lines = append(lines, theme.WarningStyle().Render(fmt.Sprintf("⚠  User caches: %v", cacheErr)))
		}
	}
	return ui.FadeUp{Lines: lines, Visible: 0}
}

func (m Model) clearCaches() tea.Cmd {
	return func() tea.Msg {
		return cacheClearDoneMsg{err: system.ClearUserCaches()}
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

	center := func(s string) string {
		return lipgloss.NewStyle().Width(width).Align(lipgloss.Center).Render(s)
	}
	muted := theme.MutedStyle()

	switch m.phase {
	case phasePackageCleanup:
		return center(muted.Render("Running package cleanup..."))

	case phaseAskUserCache:
		var pkgStatus string
		if m.pkgErr != nil {
			pkgStatus = theme.WarningStyle().Render("⚠  Package cleanup had issues")
		} else {
			pkgStatus = theme.SuccessStyle().Render("✓  Package cleanup")
		}
		sep := "   " + theme.HelpDividerStyle().Render(strings.Repeat("─", 36))
		question := lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("#ffffff")).Render("Clear user caches?")
		hint := muted.Render("thumbnails, trash, temp files")

		items := []ui.ListItem{
			{Icon: "✓", Label: "Yes, clear"},
			{Icon: "—", Label: "Skip"},
		}
		cursor := 0
		if m.cursor == actionNo {
			cursor = 1
		}
		menu := ui.RenderList(items, cursor, ui.ListConfig{Width: 40, MaxInnerWidth: 40})

		return lipgloss.JoinVertical(lipgloss.Left,
			center(pkgStatus),
			sep,
			"",
			center(question),
			center(hint),
			"",
			lipgloss.NewStyle().Width(width).Align(lipgloss.Center).Render(menu),
		)

	case phaseClearingCache:
		return center(m.shimmer.View())

	case phaseDone:
		title := lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("#ffffff")).Render("Cleanup Complete")
		prompt := muted.Render("press any key to continue")
		parts := []string{center(title), ""}
		for _, l := range m.fadeup.VisibleLines() {
			parts = append(parts, "   "+l)
		}
		parts = append(parts, "", center(prompt))
		return lipgloss.JoinVertical(lipgloss.Left, parts...)
	}

	return ""
}

func (m Model) Title() string { return "System Cleanup" }

func (m Model) HandlesBack() bool { return false }

func (m Model) ShortHelp() []string {
	if m.phase == phaseAskUserCache {
		return []string{"y yes", "n no"}
	}
	return []string{}
}
