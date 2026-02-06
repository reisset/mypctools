package app

import (
	"time"

	tea "github.com/charmbracelet/bubbletea"
)

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

// ToastMsg shows a brief toast notification that auto-dismisses.
type ToastMsg struct {
	Text    string
	IsError bool
}

// clearToastMsg is sent when the toast should be dismissed.
type clearToastMsg struct{}

// Navigate returns a tea.Cmd that pushes a screen.
func Navigate(s Screen) tea.Cmd {
	return func() tea.Msg { return NavigateMsg{Screen: s} }
}

// PopScreen returns a tea.Cmd that pops the current screen.
func PopScreen() tea.Cmd {
	return func() tea.Msg { return PopScreenMsg{} }
}

// Toast returns a tea.Cmd that shows a toast and pops back.
func Toast(text string, isError bool) tea.Cmd {
	return func() tea.Msg { return ToastMsg{Text: text, IsError: isError} }
}

// toastDuration is how long a toast stays visible.
const toastDuration = 3 * time.Second
