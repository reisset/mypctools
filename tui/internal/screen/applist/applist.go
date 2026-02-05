package applist

import (
	"fmt"
	"strings"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/reisset/mypctools/tui/internal/app"
	"github.com/reisset/mypctools/tui/internal/pkg"
	"github.com/reisset/mypctools/tui/internal/screen/appconfirm"
	"github.com/reisset/mypctools/tui/internal/state"
	"github.com/reisset/mypctools/tui/internal/theme"
	"github.com/reisset/mypctools/tui/internal/ui"
)

// Model is the multi-select app list screen.
type Model struct {
	shared    *state.Shared
	category  string
	apps      []pkg.App
	selected  map[string]bool // App ID → selected
	cursor    int
	installed map[string]bool // Cached installed status (computed once)
}

// New creates a new app list screen for the given category.
func New(shared *state.Shared, category string) Model {
	apps := pkg.AppsByCategory(category)

	// Pre-compute installed status once (avoids shell calls on every render)
	installed := make(map[string]bool)
	for _, a := range apps {
		installed[a.ID] = pkg.IsAppInstalled(&a, shared.Distro.Type)
	}

	return Model{
		shared:    shared,
		category:  category,
		apps:      apps,
		selected:  make(map[string]bool),
		cursor:    0,
		installed: installed,
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
			if m.cursor >= len(m.apps) {
				m.cursor = 0
			}
		case "k", "up":
			m.cursor--
			if m.cursor < 0 {
				m.cursor = len(m.apps) - 1
			}
		case " ":
			// Toggle selection
			if m.cursor < len(m.apps) {
				appID := m.apps[m.cursor].ID
				m.selected[appID] = !m.selected[appID]
			}
		case "enter":
			// If any apps selected, go to confirm screen
			selectedApps := m.getSelectedApps()
			if len(selectedApps) > 0 {
				return m, app.Navigate(appconfirm.New(m.shared, m.category, selectedApps))
			}
		case "a":
			// Select all uninstalled apps
			for _, a := range m.apps {
				if !m.installed[a.ID] {
					m.selected[a.ID] = true
				}
			}
		case "n":
			// Deselect all
			m.selected = make(map[string]bool)
		}
	}
	return m, nil
}

func (m Model) getSelectedApps() []pkg.App {
	var selected []pkg.App
	for _, a := range m.apps {
		if m.selected[a.ID] {
			selected = append(selected, a)
		}
	}
	return selected
}

func (m Model) View() string {
	width := m.shared.TerminalWidth
	if width == 0 {
		width = 80
	}

	// Selection count
	selectedCount := len(m.getSelectedApps())
	var subtitle string
	if selectedCount > 0 {
		subtitle = theme.AccentStyle().Render(fmt.Sprintf("%d app(s) selected", selectedCount))
	} else {
		subtitle = theme.MutedStyle().Render("Space=select, Enter=confirm")
	}
	subtitleBlock := lipgloss.NewStyle().
		Width(width).
		Align(lipgloss.Center).
		Render(subtitle)

	// App list
	var listLines []string
	cursor := theme.MenuCursorStyle()
	normal := theme.MenuItemStyle()
	selected := theme.MenuSelectedStyle()

	for i, a := range m.apps {
		// Build checkbox
		var checkbox string
		if m.selected[a.ID] {
			checkbox = theme.SuccessStyle().Render("[x]")
		} else {
			checkbox = theme.MutedStyle().Render("[ ]")
		}

		// App name with installed badge (uses cached status)
		label := a.Name
		if m.installed[a.ID] {
			label += ui.InstalledBadge()
		}

		// Install method hint
		method := pkg.InstallMethodDescription(&a, m.shared.Distro.Type)
		methodHint := theme.MutedStyle().Render(" " + method)

		fullLabel := checkbox + " " + label + methodHint

		if i == m.cursor {
			line := cursor.Render("> ") + selected.Render(fullLabel)
			listLines = append(listLines, line)
		} else {
			listLines = append(listLines, "  "+normal.Render(fullLabel))
		}
	}
	list := strings.Join(listLines, "\n")

	listBlock := lipgloss.NewStyle().
		Width(width).
		Align(lipgloss.Center).
		Render(list)

	return lipgloss.JoinVertical(lipgloss.Left,
		subtitleBlock,
		"",
		listBlock,
	)
}

func (m Model) Title() string {
	return pkg.CategoryDisplayName(m.category)
}

func (m Model) ShortHelp() []string {
	return []string{"j/k navigate", "space toggle", "a select all", "n clear", "enter confirm"}
}
