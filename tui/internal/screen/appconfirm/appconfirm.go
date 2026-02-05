package appconfirm

import (
	"fmt"
	"strings"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/reisset/mypctools/tui/internal/app"
	"github.com/reisset/mypctools/tui/internal/pkg"
	"github.com/reisset/mypctools/tui/internal/screen/appinstall"
	"github.com/reisset/mypctools/tui/internal/state"
	"github.com/reisset/mypctools/tui/internal/theme"
)

type action int

const (
	actionInstall action = iota
	actionCancel
)

// Model is the app installation confirmation screen.
type Model struct {
	shared   *state.Shared
	category string
	apps     []pkg.App
	cursor   action
}

// New creates a new confirmation screen for the selected apps.
func New(shared *state.Shared, category string, apps []pkg.App) Model {
	return Model{
		shared:   shared,
		category: category,
		apps:     apps,
		cursor:   actionInstall,
	}
}

func (m Model) Init() tea.Cmd {
	return nil
}

func (m Model) Update(msg tea.Msg) (app.Screen, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "j", "down", "k", "up", "tab":
			// Toggle between Install and Cancel
			if m.cursor == actionInstall {
				m.cursor = actionCancel
			} else {
				m.cursor = actionInstall
			}
		case "enter", " ":
			if m.cursor == actionInstall {
				return m, app.Navigate(appinstall.New(m.shared, m.category, m.apps))
			}
			// Cancel - go back
			return m, app.PopScreen()
		case "y":
			// Shortcut for install
			return m, app.Navigate(appinstall.New(m.shared, m.category, m.apps))
		case "n":
			// Shortcut for cancel
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

	// Title
	title := lipgloss.NewStyle().
		Foreground(lipgloss.Color(theme.Current.Primary)).
		Bold(true).
		Render("Confirm Installation")

	titleBlock := lipgloss.NewStyle().
		Width(width).
		Align(lipgloss.Center).
		Render(title)

	// App count
	countLine := theme.AccentStyle().Render(fmt.Sprintf("%d app(s) selected", len(m.apps)))
	countBlock := lipgloss.NewStyle().
		Width(width).
		Align(lipgloss.Center).
		Render(countLine)

	// App list with bullets
	var appLines []string
	for _, a := range m.apps {
		method := pkg.InstallMethodDescription(&a, m.shared.Distro.Type)
		line := fmt.Sprintf("  -> %s (%s)", a.Name, method)
		appLines = append(appLines, theme.MutedStyle().Render(line))
	}
	appList := strings.Join(appLines, "\n")

	appListBlock := lipgloss.NewStyle().
		Width(width).
		Align(lipgloss.Center).
		Render(appList)

	// Action buttons
	var installBtn, cancelBtn string
	cursor := theme.MenuCursorStyle()
	normal := theme.MenuItemStyle()
	selected := theme.MenuSelectedStyle()

	if m.cursor == actionInstall {
		installBtn = cursor.Render("> ") + selected.Render("Install")
		cancelBtn = "  " + normal.Render("Cancel")
	} else {
		installBtn = "  " + normal.Render("Install")
		cancelBtn = cursor.Render("> ") + selected.Render("Cancel")
	}

	buttonsBlock := lipgloss.NewStyle().
		Width(width).
		Align(lipgloss.Center).
		Render(installBtn + "\n" + cancelBtn)

	return lipgloss.JoinVertical(lipgloss.Left,
		titleBlock,
		countBlock,
		"",
		appListBlock,
		"",
		buttonsBlock,
	)
}

func (m Model) Title() string {
	return "Confirm"
}

func (m Model) ShortHelp() []string {
	return []string{"j/k navigate", "enter select", "y install", "n cancel"}
}
