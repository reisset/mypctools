package app

import tea "github.com/charmbracelet/bubbletea"

// Screen is implemented by every TUI screen.
type Screen interface {
	Init() tea.Cmd
	Update(tea.Msg) (Screen, tea.Cmd)
	View() string
	Title() string
	ShortHelp() []string // Context-specific hints only (e.g. ["y yes", "n no"])
}

// NavigateMsg pushes a new screen onto the stack.
type NavigateMsg struct {
	Screen Screen
}

// PopScreenMsg pops the current screen (go back).
type PopScreenMsg struct{}

// Navigate returns a tea.Cmd that pushes a screen.
func Navigate(s Screen) tea.Cmd {
	return func() tea.Msg { return NavigateMsg{Screen: s} }
}

// PopScreen returns a tea.Cmd that pops the current screen.
func PopScreen() tea.Cmd {
	return func() tea.Msg { return PopScreenMsg{} }
}
