package scripts

import (
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
		case "down":
			m.cursor++
			if m.cursor >= len(m.bundles) {
				m.cursor = 0
			}
		case "up":
			m.cursor--
			if m.cursor < 0 {
				m.cursor = len(m.bundles) - 1
			}
		case "enter", " ":
			if m.cursor < len(m.bundles) {
				return m, app.Navigate(scriptmenu.New(m.shared, m.bundles[m.cursor]))
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

	subtitle := lipgloss.NewStyle().
		Foreground(lipgloss.Color(theme.Current.Muted)).
		Width(width).
		Render("  Personal script bundles and configs")

	items := make([]ui.ListItem, len(m.bundles))
	for i, b := range m.bundles {
		var suffix string
		if bundle.IsInstalled(&b) {
			suffix = ui.InstalledBadge()
		} else if b.PlatformSuffix != "" {
			suffix = theme.MutedStyle().Render(b.PlatformSuffix)
		}
		items[i] = ui.ListItem{
			Icon:        "◇",
			Label:       b.Name,
			Suffix:      suffix,
			Description: b.Description,
		}
	}

	listHeight := m.shared.ContentHeight - 4
	if listHeight < 5 {
		listHeight = 5
	}

	menu := ui.RenderList(items, m.cursor, ui.ListConfig{
		Width:         width,
		MaxInnerWidth: 80,
		Height:        listHeight,
	})

	menuBlock := lipgloss.NewStyle().
		Width(width).
		Render(menu)

	return lipgloss.JoinVertical(lipgloss.Left,
		subtitle,
		"",
		menuBlock,
	)
}

func (m Model) Title() string {
	return "My Scripts"
}

func (m Model) ShortHelp() []string {
	return []string{"↑↓ navigate", "enter select"}
}
