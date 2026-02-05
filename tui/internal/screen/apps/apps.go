package apps

import (
	"strings"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/reisset/mypctools/tui/internal/app"
	"github.com/reisset/mypctools/tui/internal/pkg"
	"github.com/reisset/mypctools/tui/internal/screen/applist"
	"github.com/reisset/mypctools/tui/internal/state"
	"github.com/reisset/mypctools/tui/internal/theme"
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

	// Title
	title := lipgloss.NewStyle().
		Foreground(lipgloss.Color(theme.Current.Primary)).
		Bold(true).
		Render("Install Apps")

	titleBlock := lipgloss.NewStyle().
		Width(width).
		Align(lipgloss.Center).
		Render(title)

	subtitle := lipgloss.NewStyle().
		Foreground(lipgloss.Color(theme.Current.Muted)).
		Width(width).
		Align(lipgloss.Center).
		Render("Select a category")

	// Menu items
	var menuLines []string
	cursor := theme.MenuCursorStyle()
	normal := theme.MenuItemStyle()
	selected := theme.MenuSelectedStyle()
	muted := theme.MutedStyle()

	for i, item := range m.items {
		label := item.icon + "  " + item.label
		if item.count > 0 {
			label += muted.Render(" (" + itoa(item.count) + ")")
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
	return "Install Apps"
}

func (m Model) ShortHelp() []string {
	return []string{"j/k navigate", "enter select"}
}

// itoa converts int to string without importing strconv
func itoa(n int) string {
	if n == 0 {
		return "0"
	}
	var digits []byte
	for n > 0 {
		digits = append([]byte{byte('0' + n%10)}, digits...)
		n /= 10
	}
	return string(digits)
}
