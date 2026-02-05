package apps

import (
	"strconv"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/reisset/mypctools/tui/internal/app"
	"github.com/reisset/mypctools/tui/internal/pkg"
	"github.com/reisset/mypctools/tui/internal/screen/applist"
	"github.com/reisset/mypctools/tui/internal/state"
	"github.com/reisset/mypctools/tui/internal/theme"
	"github.com/reisset/mypctools/tui/internal/ui"
)

type menuItem struct {
	icon     string
	label    string
	category string
	count    int
}

// Model is the app category selection screen.
type Model struct {
	shared *state.Shared
	items  []menuItem
	cursor int
}

// New creates a new apps category menu.
func New(shared *state.Shared) Model {
	items := []menuItem{
		{icon: theme.Icons.AI, label: "AI Tools", category: pkg.CategoryAI, count: len(pkg.AppsByCategory(pkg.CategoryAI))},
		{icon: theme.Icons.Browser, label: "Browsers", category: pkg.CategoryBrowsers, count: len(pkg.AppsByCategory(pkg.CategoryBrowsers))},
		{icon: theme.Icons.Gaming, label: "Gaming", category: pkg.CategoryGaming, count: len(pkg.AppsByCategory(pkg.CategoryGaming))},
		{icon: theme.Icons.Media, label: "Media", category: pkg.CategoryMedia, count: len(pkg.AppsByCategory(pkg.CategoryMedia))},
		{icon: theme.Icons.Dev, label: "Dev Tools", category: pkg.CategoryDevTools, count: len(pkg.AppsByCategory(pkg.CategoryDevTools))},
		{icon: theme.Icons.Back, label: "Back", category: "back"},
	}
	return Model{
		shared: shared,
		items:  items,
		cursor: 0,
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
			if m.cursor >= len(m.items) {
				m.cursor = 0
			}
		case "k", "up":
			m.cursor--
			if m.cursor < 0 {
				m.cursor = len(m.items) - 1
			}
		case "enter", " ":
			if m.cursor < len(m.items) {
				item := m.items[m.cursor]
				if item.category == "back" {
					return m, app.PopScreen()
				}
				return m, app.Navigate(applist.New(m.shared, item.category))
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

	// Subtitle
	subtitle := lipgloss.NewStyle().
		Foreground(lipgloss.Color(theme.Current.Muted)).
		Width(width).
		Align(lipgloss.Center).
		Render("Select a category")

	// Build list items
	items := make([]ui.ListItem, len(m.items))
	for i, item := range m.items {
		var suffix string
		if item.count > 0 {
			suffix = theme.MutedStyle().Render(" (" + strconv.Itoa(item.count) + ")")
		}
		items[i] = ui.ListItem{
			Icon:   item.icon,
			Label:  item.label,
			Suffix: suffix,
		}
	}

	menu := ui.RenderList(items, m.cursor, ui.ListConfig{
		Width:         width,
		ShowCursor:    true,
		HighlightFull: true,
	})

	menuBlock := lipgloss.NewStyle().
		Width(width).
		Align(lipgloss.Center).
		Render(menu)

	return lipgloss.JoinVertical(lipgloss.Left,
		subtitle,
		"",
		menuBlock,
	)
}

func (m Model) Title() string {
	return "Install Apps"
}

func (m Model) ShortHelp() []string {
	return []string{"j/k navigate", "enter select"}
}
