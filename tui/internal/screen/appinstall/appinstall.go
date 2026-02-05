package appinstall

import (
	"fmt"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/reisset/mypctools/tui/internal/app"
	"github.com/reisset/mypctools/tui/internal/logging"
	"github.com/reisset/mypctools/tui/internal/pkg"
	"github.com/reisset/mypctools/tui/internal/state"
	"github.com/reisset/mypctools/tui/internal/system"
	"github.com/reisset/mypctools/tui/internal/theme"
)

// execDoneMsg is sent when a single app installation finishes.
type execDoneMsg struct {
	err error
}

// Model handles sequential app installation with progress tracking.
type Model struct {
	shared    *state.Shared
	category  string
	apps      []pkg.App
	current   int  // Index of app being installed
	succeeded int  // Count of successful installs
	failed    int  // Count of failed installs
	done      bool // All installations complete
	running   bool // Currently running an install
}

// New creates an app installation screen.
func New(shared *state.Shared, category string, apps []pkg.App) Model {
	return Model{
		shared:   shared,
		category: category,
		apps:     apps,
		current:  0,
	}
}

func (m Model) Init() tea.Cmd {
	// Start installing the first app
	return m.installCurrent()
}

func (m Model) installCurrent() tea.Cmd {
	if m.current >= len(m.apps) {
		return nil
	}

	currentApp := m.apps[m.current]
	cmd := pkg.BuildInstallCmd(&currentApp, m.shared.Distro.Type)
	if cmd == nil {
		// No install method available, skip this app
		return func() tea.Msg {
			return execDoneMsg{err: fmt.Errorf("no installation method available")}
		}
	}

	// Use tea.ExecProcess to give the install full terminal control
	return tea.ExecProcess(cmd, func(err error) tea.Msg {
		return execDoneMsg{err: err}
	})
}

func (m Model) Update(msg tea.Msg) (app.Screen, tea.Cmd) {
	switch msg := msg.(type) {
	case execDoneMsg:
		// Log and update counters
		appName := m.apps[m.current].Name
		if msg.err != nil {
			m.failed++
			logging.LogAction(fmt.Sprintf("App install failed: %s", appName))
		} else {
			m.succeeded++
			logging.LogAction(fmt.Sprintf("App installed: %s", appName))
		}

		// Move to next app
		m.current++

		if m.current >= len(m.apps) {
			// All done
			m.done = true
			if len(m.apps) > 1 {
				system.Notify("mypctools", fmt.Sprintf("Installed %d apps (%d failed)", m.succeeded, m.failed))
			} else if m.succeeded > 0 {
				system.Notify("mypctools", fmt.Sprintf("%s installed", appName))
			}
			return m, nil
		}

		// Install next app
		return m, m.installCurrent()

	case tea.KeyMsg:
		if m.done {
			// Any key returns to category menu (pop twice: confirm + applist)
			return m, tea.Batch(app.PopScreen(), app.PopScreen())
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
		// Summary view
		title := lipgloss.NewStyle().
			Foreground(lipgloss.Color(theme.Current.Primary)).
			Bold(true).
			Render("Installation Complete")

		titleBlock := lipgloss.NewStyle().
			Width(width).
			Align(lipgloss.Center).
			Render(title)

		// Stats
		var statsLines []string
		if m.succeeded > 0 {
			statsLines = append(statsLines, theme.SuccessStyle().Render(fmt.Sprintf("Succeeded: %d", m.succeeded)))
		}
		if m.failed > 0 {
			statsLines = append(statsLines, theme.ErrorStyle().Render(fmt.Sprintf("Failed: %d", m.failed)))
		}

		stats := ""
		for _, line := range statsLines {
			stats += lipgloss.NewStyle().
				Width(width).
				Align(lipgloss.Center).
				Render(line) + "\n"
		}

		prompt := theme.MutedStyle().Render("Press any key to continue...")
		promptBlock := lipgloss.NewStyle().
			Width(width).
			Align(lipgloss.Center).
			Render(prompt)

		content = lipgloss.JoinVertical(lipgloss.Left,
			"",
			titleBlock,
			"",
			stats,
			"",
			promptBlock,
		)
	} else {
		// Progress view
		currentApp := m.apps[m.current]
		progress := fmt.Sprintf("[%d/%d]", m.current+1, len(m.apps))

		title := lipgloss.NewStyle().
			Foreground(lipgloss.Color(theme.Current.Primary)).
			Bold(true).
			Render(progress + " Installing " + currentApp.Name + "...")

		titleBlock := lipgloss.NewStyle().
			Width(width).
			Align(lipgloss.Center).
			Render(title)

		method := pkg.InstallMethodDescription(&currentApp, m.shared.Distro.Type)
		methodLine := theme.MutedStyle().Render(method)
		methodBlock := lipgloss.NewStyle().
			Width(width).
			Align(lipgloss.Center).
			Render(methodLine)

		content = lipgloss.JoinVertical(lipgloss.Left,
			"",
			titleBlock,
			methodBlock,
		)
	}

	return content
}

func (m Model) Title() string {
	if m.done {
		return "Complete"
	}
	if m.current < len(m.apps) {
		return fmt.Sprintf("Installing %s", m.apps[m.current].Name)
	}
	return "Installing"
}

func (m Model) ShortHelp() []string {
	if m.done {
		return []string{"any key continue"}
	}
	return []string{}
}
