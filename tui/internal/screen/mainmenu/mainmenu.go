package mainmenu

import (
	"fmt"
	"os"
	"os/user"
	"strings"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/reisset/mypctools/tui/internal/app"
	"github.com/reisset/mypctools/tui/internal/state"
	"github.com/reisset/mypctools/tui/internal/theme"
)

const logo = `███╗   ███╗██╗   ██╗██████╗  ██████╗████████╗ ██████╗  ██████╗ ██╗     ███████╗
████╗ ████║╚██╗ ██╔╝██╔══██╗██╔════╝╚══██╔══╝██╔═══██╗██╔═══██╗██║     ██╔════╝
██╔████╔██║ ╚████╔╝ ██████╔╝██║        ██║   ██║   ██║██║   ██║██║     ███████╗
██║╚██╔╝██║  ╚██╔╝  ██╔═══╝ ██║        ██║   ██║   ██║██║   ██║██║     ╚════██║
██║ ╚═╝ ██║   ██║   ██║     ╚██████╗   ██║   ╚██████╔╝╚██████╔╝███████╗███████║
╚═╝     ╚═╝   ╚═╝   ╚═╝      ╚═════╝   ╚═╝    ╚═════╝  ╚═════╝ ╚══════╝╚══════╝`

type menuItem struct {
	icon  string
	label string
	id    string
}

// Model is the main menu screen.
type Model struct {
	shared   *state.Shared
	items    []menuItem
	cursor   int
}

func New(shared *state.Shared) Model {
	return Model{
		shared: shared,
		cursor: 0,
	}
}

func (m Model) buildItems() []menuItem {
	items := []menuItem{
		{icon: theme.Icons.Apps, label: "Install Apps", id: "apps"},
		{icon: theme.Icons.Scripts, label: "My Scripts", id: "scripts"},
		{icon: theme.Icons.System, label: "System Setup", id: "system"},
	}
	if m.shared.UpdateCount > 0 {
		items = append(items, menuItem{
			icon:  theme.Icons.Update,
			label: fmt.Sprintf("Pull Updates (%d new)", m.shared.UpdateCount),
			id:    "update",
		})
	}
	items = append(items, menuItem{icon: theme.Icons.Exit, label: "Exit", id: "exit"})
	return items
}

func (m Model) Init() tea.Cmd {
	return nil
}

func (m Model) Update(msg tea.Msg) (app.Screen, tea.Cmd) {
	items := m.buildItems()

	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "q":
			return m, tea.Quit
		case "j", "down":
			m.cursor++
			if m.cursor >= len(items) {
				m.cursor = 0
			}
		case "k", "up":
			m.cursor--
			if m.cursor < 0 {
				m.cursor = len(items) - 1
			}
		case "enter":
			if m.cursor < len(items) {
				return m, m.handleSelection(items[m.cursor].id)
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
		// Phase 3: will navigate to app categories
		return nil
	case "scripts":
		// Phase 2: will navigate to script list
		return nil
	case "system":
		// Phase 4: will navigate to system setup menu
		return nil
	case "update":
		// Phase 4: will navigate to pull update screen
		return nil
	}
	return nil
}

func (m Model) View() string {
	items := m.buildItems()
	width := m.shared.TerminalWidth
	if width == 0 {
		width = 80
	}

	// Logo
	logoStyle := lipgloss.NewStyle().
		Foreground(lipgloss.Color(theme.Current.Primary)).
		Width(width).
		Align(lipgloss.Center)
	renderedLogo := logoStyle.Render(logo)

	// Update badge
	var updateBadge string
	if m.shared.UpdateCount > 0 {
		updateBadge = lipgloss.NewStyle().
			Foreground(lipgloss.Color(theme.Current.Muted)).
			Width(width).
			Align(lipgloss.Center).
			Render(fmt.Sprintf("⬆ Update available (%d new)", m.shared.UpdateCount))
	}

	// System info line
	sysLine := buildSysLine(m.shared)
	sysLineRendered := lipgloss.NewStyle().
		Foreground(lipgloss.Color(theme.Current.Muted)).
		Width(width).
		Align(lipgloss.Center).
		Render(sysLine)

	// Menu items
	var menuLines []string
	cursor := theme.MenuCursorStyle()
	normal := theme.MenuItemStyle()
	selected := theme.MenuSelectedStyle()

	for i, item := range items {
		label := item.icon + "  " + item.label
		if i == m.cursor {
			line := cursor.Render("> ") + selected.Render(label)
			menuLines = append(menuLines, line)
		} else {
			menuLines = append(menuLines, "  "+normal.Render(label))
		}
	}
	menu := strings.Join(menuLines, "\n")

	// Center the menu
	menuBlock := lipgloss.NewStyle().
		Width(width).
		Align(lipgloss.Center).
		Render(menu)

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
	return []string{"j/k navigate", "enter select"}
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

	hostname := "localhost"
	if u, err := user.Current(); err == nil {
		_ = u
	}
	if h, err := os.Hostname(); err == nil {
		hostname = h
	}
	_ = hostname

	kernel := ""
	if data, err := os.ReadFile("/proc/version"); err == nil {
		fields := strings.Fields(string(data))
		if len(fields) >= 3 {
			kernel = fields[2]
		}
	}

	parts := []string{shared.Distro.Name}
	if kernel != "" {
		parts = append(parts, kernel)
	}
	parts = append(parts, shell)

	return strings.Join(parts, " · ")
}
