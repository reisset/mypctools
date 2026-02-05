package app

import (
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/reisset/mypctools/tui/internal/state"
	"github.com/reisset/mypctools/tui/internal/ui"
)

// Model is the root Bubble Tea model. It holds a screen stack and shared state.
type Model struct {
	stack  []Screen
	shared *state.Shared
	width  int
	height int
}

// NewModel creates the root model with an initial screen.
func NewModel(initial Screen, shared *state.Shared) Model {
	return Model{
		stack:  []Screen{initial},
		shared: shared,
	}
}

func (m Model) Init() tea.Cmd {
	if len(m.stack) > 0 {
		return m.stack[len(m.stack)-1].Init()
	}
	return nil
}

func (m Model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
		m.shared.TerminalWidth = msg.Width
		m.shared.TerminalHeight = msg.Height

	case state.UpdateCountMsg:
		m.shared.UpdateCount = msg.Count

	case NavigateMsg:
		m.stack = append(m.stack, msg.Screen)
		return m, msg.Screen.Init()

	case PopScreenMsg:
		if len(m.stack) > 1 {
			m.stack = m.stack[:len(m.stack)-1]
			return m, m.stack[len(m.stack)-1].Init()
		}
		return m, tea.Quit

	case tea.KeyMsg:
		switch msg.String() {
		case "ctrl+c":
			return m, tea.Quit
		case "esc":
			if len(m.stack) > 1 {
				m.stack = m.stack[:len(m.stack)-1]
				return m, m.stack[len(m.stack)-1].Init()
			}
			return m, tea.Quit
		}
	}

	// Delegate to the active screen
	if len(m.stack) > 0 {
		top := m.stack[len(m.stack)-1]
		updated, cmd := top.Update(msg)
		m.stack[len(m.stack)-1] = updated
		return m, cmd
	}

	return m, nil
}

func (m Model) View() string {
	if len(m.stack) == 0 {
		return ""
	}

	top := m.stack[len(m.stack)-1]
	width := m.width
	if width == 0 {
		width = 80
	}

	// Build header: breadcrumb from stack titles (only for sub-screens)
	var header string
	if len(m.stack) > 1 {
		titles := make([]string, len(m.stack))
		for i, s := range m.stack {
			titles[i] = s.Title()
		}
		header = ui.Breadcrumb(titles, width) + "\n\n"
	}

	// Build footer: help keys from active screen + global keys
	helpKeys := []ui.HelpKey{}
	for _, h := range top.ShortHelp() {
		helpKeys = append(helpKeys, ui.HelpKey{Key: h, Desc: ""})
	}
	if len(m.stack) > 1 {
		helpKeys = append(helpKeys, ui.HelpKey{Key: "esc", Desc: "back"})
	}
	helpKeys = append(helpKeys, ui.HelpKey{Key: "q", Desc: "quit"})

	footer := "\n" + ui.Footer(helpKeys, width)

	// Compose view - each component already handles its own centering via Width(width).Align(Center)
	content := top.View()

	// Calculate vertical centering
	// Only center if content is less than 70% of screen height (avoids centering scrolling content)
	contentHeight := lipgloss.Height(header + content + footer)
	verticalPadding := 0
	if m.height > contentHeight && contentHeight < (m.height*7/10) {
		verticalPadding = (m.height - contentHeight) / 2
	}

	// Simple string concatenation - each part already has full width with centered content
	combined := header + content + footer

	if verticalPadding > 0 {
		return lipgloss.NewStyle().
			MarginTop(verticalPadding).
			Render(combined)
	}
	return combined
}
