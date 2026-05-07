package ui

import (
	"time"

	tea "github.com/charmbracelet/bubbletea"
)

const fadeInterval = 150 * time.Millisecond

// FadeTickMsg drives the fade-up stagger animation.
type FadeTickMsg struct{}

// FadeUp reveals lines one-by-one with a staggered delay.
type FadeUp struct {
	Lines   []string
	Visible int
}

// Start returns the first tick command to begin the animation.
func (f *FadeUp) Start() tea.Cmd {
	if len(f.Lines) == 0 {
		return nil
	}
	return tea.Tick(fadeInterval, func(t time.Time) tea.Msg {
		return FadeTickMsg{}
	})
}

// Update reveals one more line per tick and schedules the next tick.
func (f *FadeUp) Update(msg tea.Msg) tea.Cmd {
	if _, ok := msg.(FadeTickMsg); ok {
		if f.Visible < len(f.Lines) {
			f.Visible++
			if f.Visible < len(f.Lines) {
				return tea.Tick(fadeInterval, func(t time.Time) tea.Msg {
					return FadeTickMsg{}
				})
			}
		}
	}
	return nil
}

// VisibleLines returns the lines that should be shown so far.
func (f FadeUp) VisibleLines() []string {
	if f.Visible <= 0 {
		return nil
	}
	end := f.Visible
	if end > len(f.Lines) {
		end = len(f.Lines)
	}
	return f.Lines[:end]
}
