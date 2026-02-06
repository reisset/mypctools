package mainmenu

import (
	"fmt"
	"os"
	"strings"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/reisset/mypctools/tui/internal/app"
	"github.com/reisset/mypctools/tui/internal/screen/apps"
	"github.com/reisset/mypctools/tui/internal/screen/pullupdate"
	"github.com/reisset/mypctools/tui/internal/screen/scripts"
	"github.com/reisset/mypctools/tui/internal/screen/systemsetup"
	"github.com/reisset/mypctools/tui/internal/state"
	"github.com/reisset/mypctools/tui/internal/theme"
	"github.com/reisset/mypctools/tui/internal/ui"
)

const logo = `███╗   ███╗██╗   ██╗██████╗  ██████╗████████╗ ██████╗  ██████╗ ██╗     ███████╗
████╗ ████║╚██╗ ██╔╝██╔══██╗██╔════╝╚══██╔══╝██╔═══██╗██╔═══██╗██║     ██╔════╝
██╔████╔██║ ╚████╔╝ ██████╔╝██║        ██║   ██║   ██║██║   ██║██║     ███████╗
██║╚██╔╝██║  ╚██╔╝  ██╔═══╝ ██║        ██║   ██║   ██║██║   ██║██║     ╚════██║
██║ ╚═╝ ██║   ██║   ██║     ╚██████╗   ██║   ╚██████╔╝╚██████╔╝███████╗███████║
╚═╝     ╚═╝   ╚═╝   ╚═╝      ╚═════╝   ╚═╝    ╚═════╝  ╚═════╝ ╚══════╝╚══════╝`

// Compact logo for narrow terminals
const logoCompact = `╔╦╗╦ ╦╔═╗╔═╗╔╦╗╔═╗╔═╗╦  ╔═╗
║║║╚╦╝╠═╝║   ║ ║ ║║ ║║  ╚═╗
╩ ╩ ╩ ╩  ╚═╝ ╩ ╚═╝╚═╝╩═╝╚═╝`

type menuItem struct {
	icon  string
	label string
	id    string
}

// Model is the main menu screen.
type Model struct {
	shared          *state.Shared
	items           []menuItem
	cursor          int
	lastUpdateCount int
}

func New(shared *state.Shared) Model {
	m := Model{
		shared:          shared,
		cursor:          0,
		lastUpdateCount: -1, // Force initial build
	}
	m.rebuildItemsIfNeeded()
	return m
}

func (m *Model) rebuildItemsIfNeeded() {
	if m.lastUpdateCount == m.shared.UpdateCount {
		return
	}
	m.lastUpdateCount = m.shared.UpdateCount
	m.items = []menuItem{
		{icon: theme.Icons.Apps, label: "Install Apps", id: "apps"},
		{icon: theme.Icons.Scripts, label: "My Scripts", id: "scripts"},
		{icon: theme.Icons.System, label: "System Setup", id: "system"},
	}
	if m.shared.UpdateCount > 0 {
		m.items = append(m.items, menuItem{
			icon:  theme.Icons.Update,
			label: fmt.Sprintf("Pull Updates (%d new)", m.shared.UpdateCount),
			id:    "update",
		})
	}
	m.items = append(m.items, menuItem{icon: theme.Icons.Exit, label: "Exit", id: "exit"})
	if m.cursor >= len(m.items) {
		m.cursor = len(m.items) - 1
	}
}

func (m Model) Init() tea.Cmd {
	return nil
}

func (m Model) Update(msg tea.Msg) (app.Screen, tea.Cmd) {
	m.rebuildItemsIfNeeded()

	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "down":
			m.cursor++
			if m.cursor >= len(m.items) {
				m.cursor = 0
			}
		case "up":
			m.cursor--
			if m.cursor < 0 {
				m.cursor = len(m.items) - 1
			}
		case "enter", " ":
			if m.cursor < len(m.items) {
				return m, m.handleSelection(m.items[m.cursor].id)
			}
		}
	}
	return m, nil
}

func (m Model) handleSelection(id string) tea.Cmd {
	switch id {
	case "exit":
		return tea.Quit
	case "apps":
		return app.Navigate(apps.New(m.shared))
	case "scripts":
		return app.Navigate(scripts.New(m.shared))
	case "system":
		return app.Navigate(systemsetup.New(m.shared))
	case "update":
		return app.Navigate(pullupdate.New(m.shared))
	}
	return nil
}

func (m Model) View() string {
	width := m.shared.TerminalWidth
	if width == 0 {
		width = 80
	}

	// Choose logo based on width
	currentLogo := logo
	if width < 85 {
		currentLogo = logoCompact
	}

	// Logo
	logoStyle := lipgloss.NewStyle().
		Foreground(lipgloss.Color(theme.Current.Primary)).
		Width(width).
		Align(lipgloss.Center)
	renderedLogo := logoStyle.Render(currentLogo)

	// Update badge
	var updateBadge string
	if m.shared.UpdateCount > 0 {
		updateBadge = lipgloss.NewStyle().
			Foreground(lipgloss.Color(theme.Current.Accent)).
			Width(width).
			Align(lipgloss.Center).
			Render(fmt.Sprintf("%s Update available (%d new)", theme.Icons.Update, m.shared.UpdateCount))
	}

	// System info line with better spacing
	sysLine := buildSysLine(m.shared)
	sysLineRendered := lipgloss.NewStyle().
		Foreground(lipgloss.Color(theme.Current.Muted)).
		Width(width).
		Align(lipgloss.Center).
		Render(sysLine)

	// Menu items using new list component
	items := make([]ui.ListItem, len(m.items))
	for i, item := range m.items {
		items[i] = ui.ListItem{
			Icon:  item.icon,
			Label: item.label,
		}
	}

	menu := ui.RenderList(items, m.cursor, ui.ListConfig{
		Width:         width,
		ShowCursor:    true,
		HighlightFull: true,
	})

	// Wrap menu in a subtle box for visual containment
	menuBox := theme.BoxStyle().
		Width(56).
		Align(lipgloss.Left).
		Render(menu)

	// Center the menu
	menuBlock := lipgloss.NewStyle().
		Width(width).
		Align(lipgloss.Center).
		Render(menuBox)

	parts := []string{renderedLogo}
	if updateBadge != "" {
		parts = append(parts, updateBadge)
	}
	parts = append(parts, sysLineRendered, "", menuBlock)

	return lipgloss.JoinVertical(lipgloss.Left, parts...)
}

func (m Model) Title() string {
	return "Main Menu"
}

func (m Model) ShortHelp() []string {
	return []string{"enter select"}
}

func buildSysLine(shared *state.Shared) string {
	shell := os.Getenv("SHELL")
	if shell != "" {
		// Extract just the shell name
		parts := strings.Split(shell, "/")
		shell = parts[len(parts)-1]
	} else {
		shell = "sh"
	}

	kernel := ""
	if data, err := os.ReadFile("/proc/version"); err == nil {
		fields := strings.Fields(string(data))
		if len(fields) >= 3 {
			kernel = fields[2]
		}
	}

	// Build with better spacing using dots
	parts := []string{shared.Distro.Name}
	if kernel != "" {
		parts = append(parts, kernel)
	}
	parts = append(parts, shell)

	return strings.Join(parts, "  " + theme.Icons.Dot + "  ")
}
