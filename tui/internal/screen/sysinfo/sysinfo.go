package sysinfo

import (
	"fmt"
	"strings"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/reisset/mypctools/tui/internal/app"
	"github.com/reisset/mypctools/tui/internal/state"
	"github.com/reisset/mypctools/tui/internal/system"
	"github.com/reisset/mypctools/tui/internal/theme"
	"github.com/reisset/mypctools/tui/internal/ui"
)

// Model handles the system info display screen.
type Model struct {
	shared *state.Shared
	info   system.SystemInfo
}

// New creates a new system info screen.
func New(shared *state.Shared) Model {
	return Model{
		shared: shared,
		info:   system.GatherSystemInfo(shared.Distro),
	}
}

func (m Model) Init() tea.Cmd {
	return nil
}

func (m Model) Update(msg tea.Msg) (app.Screen, tea.Cmd) {
	switch msg.(type) {
	case tea.KeyMsg:
		// Any key goes back
		return m, app.PopScreen()
	}
	return m, nil
}

func (m Model) View() string {
	width := m.shared.TerminalWidth
	if width == 0 {
		width = 80
	}

	// Build system info content
	var sysLines []string
	if m.info.User != "" {
		sysLines = append(sysLines, formatLine("User", m.info.User))
	}
	if m.info.OS != "" {
		sysLines = append(sysLines, formatLine("OS", m.info.OS))
	}
	if m.info.Host != "" {
		sysLines = append(sysLines, formatLine("Host", m.info.Host))
	}
	if m.info.Kernel != "" {
		sysLines = append(sysLines, formatLine("Kernel", m.info.Kernel))
	}
	if m.info.Uptime != "" {
		sysLines = append(sysLines, formatLine("Uptime", m.info.Uptime))
	}
	if m.info.Packages != "" {
		sysLines = append(sysLines, formatLine("Packages", m.info.Packages))
	}
	if m.info.Shell != "" {
		sysLines = append(sysLines, formatLine("Shell", m.info.Shell))
	}
	if m.info.DE != "" {
		sysLines = append(sysLines, formatLine("DE", m.info.DE))
	}
	if m.info.Terminal != "" {
		sysLines = append(sysLines, formatLine("Terminal", m.info.Terminal))
	}

	// Build hardware info content
	var hwLines []string
	if m.info.CPU != "" {
		hwLines = append(hwLines, formatLine("CPU", m.info.CPU))
	}
	if m.info.GPU != "" {
		hwLines = append(hwLines, formatLine("GPU", m.info.GPU))
	}
	if m.info.Memory != "" {
		hwLines = append(hwLines, formatLine("Memory", m.info.Memory))
	}
	if m.info.Disk != "" {
		hwLines = append(hwLines, formatLine("Disk (/)", m.info.Disk))
	}

	// Decide layout based on width
	if width >= 90 {
		// Two-column layout with titled boxes
		colWidth := (width / 2) - 4

		sysContent := strings.Join(sysLines, "\n")
		hwContent := strings.Join(hwLines, "\n")

		leftBox := ui.TitledBox("System", sysContent, colWidth, true)
		rightBox := ui.TitledBox("Hardware", hwContent, colWidth, true)

		infoBlock := lipgloss.JoinHorizontal(lipgloss.Top, leftBox, "  ", rightBox)

		infoBlockCentered := lipgloss.NewStyle().
			Width(width).
			Align(lipgloss.Center).
			Render(infoBlock)

		prompt := theme.MutedStyle().Render("Press any key to continue...")
		promptBlock := lipgloss.NewStyle().
			Width(width).
			Align(lipgloss.Center).
			Render(prompt)

		return lipgloss.JoinVertical(lipgloss.Left,
			"",
			infoBlockCentered,
			"",
			promptBlock,
		)
	}

	// Single column layout for narrow terminals
	allLines := append(sysLines, hwLines...)
	allContent := strings.Join(allLines, "\n")

	singleBox := ui.TitledBox("System Info", allContent, width-4, true)

	boxCentered := lipgloss.NewStyle().
		Width(width).
		Align(lipgloss.Center).
		Render(singleBox)

	prompt := theme.MutedStyle().Render("Press any key to continue...")
	promptBlock := lipgloss.NewStyle().
		Width(width).
		Align(lipgloss.Center).
		Render(prompt)

	return lipgloss.JoinVertical(lipgloss.Left,
		"",
		boxCentered,
		"",
		promptBlock,
	)
}

func (m Model) Title() string {
	return "System Info"
}

func (m Model) ShortHelp() []string {
	return []string{"any key back"}
}

// formatLine formats a key-value line with proper alignment and coloring.
func formatLine(key, value string) string {
	keyStyle := theme.MutedStyle()
	valueStyle := theme.PrimaryStyle()
	return fmt.Sprintf("  %s  %s", keyStyle.Render(fmt.Sprintf("%-10s", key)), valueStyle.Render(value))
}
