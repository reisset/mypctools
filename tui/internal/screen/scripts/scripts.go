package scripts

import (
	"strings"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/reisset/mypctools/tui/internal/app"
	"github.com/reisset/mypctools/tui/internal/bundle"
	"github.com/reisset/mypctools/tui/internal/screen/scriptmenu"
	"github.com/reisset/mypctools/tui/internal/state"
	"github.com/reisset/mypctools/tui/internal/theme"
	"github.com/reisset/mypctools/tui/internal/ui"
)

// Model is the script bundles list screen.
type Model struct {
	shared  *state.Shared
	bundles []bundle.Bundle
	cursor  int
}

// New creates a new scripts list screen.
func New(shared *state.Shared) Model {
	return Model{
		shared:  shared,
		bundles: bundle.All(),
		cursor:  0,
	}
}

func (m Model) Init() tea.Cmd {
	return nil
}

func (m Model) Update(msg tea.Msg) (app.Screen, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "j", "down":
			m.cursor++
			if m.cursor >= len(m.bundles) {
				m.cursor = 0
			}
		case "k", "up":
			m.cursor--
			if m.cursor < 0 {
				m.cursor = len(m.bundles) - 1
			}
		case "enter", " ":
			if m.cursor < len(m.bundles) {
				b := m.bundles[m.cursor]
				return m, app.Navigate(scriptmenu.New(m.shared, b))
			}
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
		Render("My Scripts")

	titleBlock := lipgloss.NewStyle().
		Width(width).
		Align(lipgloss.Center).
		Render(title)

	subtitle := lipgloss.NewStyle().
		Foreground(lipgloss.Color(theme.Current.Muted)).
		Width(width).
		Align(lipgloss.Center).
		Render("Personal script bundles and configs")

	// Menu items
	var menuLines []string
	cursor := theme.MenuCursorStyle()
	normal := theme.MenuItemStyle()
	selected := theme.MenuSelectedStyle()

	for i, b := range m.bundles {
		label := theme.Icons.Scripts + "  " + b.Name
		if bundle.IsInstalled(&b) {
			label += ui.InstalledBadge()
		}

		if i == m.cursor {
			line := cursor.Render("> ") + selected.Render(label)
			menuLines = append(menuLines, line)
		} else {
			menuLines = append(menuLines, "  "+normal.Render(label))
		}
	}
	menu := strings.Join(menuLines, "\n")

	menuBlock := lipgloss.NewStyle().
		Width(width).
		Align(lipgloss.Center).
		Render(menu)

	return lipgloss.JoinVertical(lipgloss.Left,
		titleBlock,
		subtitle,
		"",
		menuBlock,
	)
}

func (m Model) Title() string {
	return "My Scripts"
}

func (m Model) ShortHelp() []string {
	return []string{"j/k navigate", "enter select"}
}
