package ui

import (
	"time"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/reisset/mypctools/tui/internal/theme"
)

const shimmerInterval = 80 * time.Millisecond
const shimmerWindow = 4

// ShimmerTickMsg drives the shimmer animation.
type ShimmerTickMsg struct{}

// Shimmer animates a "bright window" scanning left-to-right across text.
type Shimmer struct {
	Text   string
	Offset int
}

// Tick returns a command that fires the next shimmer frame.
// Returns nil if Text is empty (no animation needed).
func (s Shimmer) Tick() tea.Cmd {
	if len(s.Text) == 0 {
		return nil
	}
	return tea.Tick(shimmerInterval, func(t time.Time) tea.Msg {
		return ShimmerTickMsg{}
	})
}

// Update handles a ShimmerTickMsg and returns the next tick command.
func (s *Shimmer) Update(msg tea.Msg) tea.Cmd {
	if _, ok := msg.(ShimmerTickMsg); ok {
		n := len([]rune(s.Text))
		if n == 0 {
			n = 1
		}
		s.Offset = (s.Offset + 1) % (n + shimmerWindow)
		return s.Tick()
	}
	return nil
}

// View renders the shimmer text with a moving bright window.
func (s Shimmer) View() string {
	runes := []rune(s.Text)
	bright := lipgloss.NewStyle().Foreground(lipgloss.Color(theme.Current.Primary)).Bold(true)
	dim := lipgloss.NewStyle().Foreground(lipgloss.Color(theme.Current.Muted))

	result := ""
	for i, ch := range runes {
		dist := i - s.Offset
		if dist < 0 {
			dist = -dist
		}
		if dist < shimmerWindow {
			result += bright.Render(string(ch))
		} else {
			result += dim.Render(string(ch))
		}
	}
	return result
}
