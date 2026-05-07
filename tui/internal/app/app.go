package app

import (
	"fmt"
	"time"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/reisset/mypctools/tui/internal/state"
	"github.com/reisset/mypctools/tui/internal/theme"
	"github.com/reisset/mypctools/tui/internal/ui"
)

// Model is the root Bubble Tea model.
type Model struct {
	stack       []Screen
	shared      *state.Shared
	width       int
	height      int
	toast       string
	toastError  bool
	toastFading bool
	toastExpiry time.Time
}

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
		ch := msg.Height - 8
		if ch < 5 {
			ch = 5
		}
		m.shared.ContentHeight = ch

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

	case ToastMsg:
		m.toast = msg.Text
		m.toastError = msg.IsError
		m.toastFading = false
		m.toastExpiry = time.Now().Add(toastDuration)
		if len(m.stack) > 1 {
			m.stack = m.stack[:len(m.stack)-1]
		}
		return m, tea.Batch(
			tea.Tick(toastDuration-500*time.Millisecond, func(t time.Time) tea.Msg {
				return fadeToastMsg{}
			}),
			tea.Tick(toastDuration, func(t time.Time) tea.Msg {
				return clearToastMsg{}
			}),
		)

	case fadeToastMsg:
		if m.toast != "" {
			m.toastFading = true
		}
		return m, nil

	case clearToastMsg:
		if !m.toastExpiry.IsZero() && time.Now().After(m.toastExpiry) {
			m.toast = ""
			m.toastFading = false
		}
		return m, nil

	case tea.KeyMsg:
		switch msg.String() {
		case "ctrl+c":
			return m, tea.Quit
		case "esc":
			return m, PopScreen()
		}
	}

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

	if m.width > 0 && m.height > 0 && (m.width < theme.MinWidth || m.height < theme.MinHeight) {
		text := fmt.Sprintf("Terminal too small (%dx%d)\nResize to at least %dx%d",
			m.width, m.height, theme.MinWidth, theme.MinHeight)
		return lipgloss.NewStyle().
			Width(m.width).Height(m.height).
			Align(lipgloss.Center, lipgloss.Center).
			Foreground(lipgloss.Color(theme.Current.Muted)).
			Render(text)
	}

	top := m.stack[len(m.stack)-1]
	width := m.width
	if width == 0 {
		width = 80
	}

	// Header: "← Title" for sub-screens only
	var header string
	if len(m.stack) > 1 {
		title := top.Title()
		header = ui.ScreenHeader(title, width) + "\n"
	}

	// Build footer keys
	helpKeys := []ui.HelpKey{}
	for _, h := range top.ShortHelp() {
		helpKeys = append(helpKeys, ui.ParseHelpString(h))
	}
	if len(m.stack) > 1 {
		helpKeys = append(helpKeys, ui.HelpKey{Key: "esc", Desc: "back"})
	}

	// Toast line
	var toastLine string
	if m.toast != "" {
		toastColor := theme.Current.Success
		if m.toastError {
			toastColor = theme.Current.Error
		}
		if m.toastFading {
			toastColor = theme.Current.Muted
		}
		toastStyle := lipgloss.NewStyle().
			Foreground(lipgloss.Color(toastColor)).
			Bold(!m.toastFading)
		toastLine = "\n" + lipgloss.NewStyle().
			Width(width).
			Align(lipgloss.Center).
			Render(toastStyle.Render(m.toast))
	}

	footer := toastLine + "\n" + ui.Footer(helpKeys, width)

	content := top.View()

	contentHeight := lipgloss.Height(header + content + footer)
	verticalPadding := 0
	if m.height > contentHeight && contentHeight < (m.height*7/10) {
		verticalPadding = (m.height - contentHeight) / 2
	}

	combined := header + content + footer

	if verticalPadding > 0 {
		return lipgloss.NewStyle().MarginTop(verticalPadding).Render(combined)
	}
	return combined
}
