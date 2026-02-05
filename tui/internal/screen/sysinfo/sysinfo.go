package sysinfo

import (
	"fmt"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/reisset/mypctools/tui/internal/app"
	"github.com/reisset/mypctools/tui/internal/state"
	"github.com/reisset/mypctools/tui/internal/system"
	"github.com/reisset/mypctools/tui/internal/theme"
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
	sysLines := []string{}
	if m.info.User != "" {
		sysLines = append(sysLines, fmt.Sprintf("  User       %s", m.info.User))
	}
	if m.info.OS != "" {
		sysLines = append(sysLines, fmt.Sprintf("  OS         %s", m.info.OS))
	}
	if m.info.Host != "" {
		sysLines = append(sysLines, fmt.Sprintf("  Host       %s", m.info.Host))
	}
	if m.info.Kernel != "" {
		sysLines = append(sysLines, fmt.Sprintf("  Kernel     %s", m.info.Kernel))
	}
	if m.info.Uptime != "" {
		sysLines = append(sysLines, fmt.Sprintf("  Uptime     %s", m.info.Uptime))
	}
	if m.info.Packages != "" {
		sysLines = append(sysLines, fmt.Sprintf("  Packages   %s", m.info.Packages))
	}
	if m.info.Shell != "" {
		sysLines = append(sysLines, fmt.Sprintf("  Shell      %s", m.info.Shell))
	}
	if m.info.DE != "" {
		sysLines = append(sysLines, fmt.Sprintf("  DE         %s", m.info.DE))
	}
	if m.info.Terminal != "" {
		sysLines = append(sysLines, fmt.Sprintf("  Terminal   %s", m.info.Terminal))
	}

	// Build hardware info content
	hwLines := []string{}
	if m.info.CPU != "" {
		hwLines = append(hwLines, fmt.Sprintf("  CPU        %s", m.info.CPU))
	}
	if m.info.GPU != "" {
		hwLines = append(hwLines, fmt.Sprintf("  GPU        %s", m.info.GPU))
	}
	if m.info.Memory != "" {
		hwLines = append(hwLines, fmt.Sprintf("  Memory     %s", m.info.Memory))
	}
	if m.info.Disk != "" {
		hwLines = append(hwLines, fmt.Sprintf("  Disk (/)   %s", m.info.Disk))
	}

	// Box styles
	boxStyle := lipgloss.NewStyle().
		Border(lipgloss.RoundedBorder()).
		BorderForeground(lipgloss.Color(theme.Current.Secondary)).
		Foreground(lipgloss.Color(theme.Current.Primary)).
		Padding(1, 2)

	// Decide layout based on width
	if width >= 90 {
		// Two-column layout
		colWidth := (width / 2) - 4

		sysContent := ""
		for i, line := range sysLines {
			sysContent += line
			if i < len(sysLines)-1 {
				sysContent += "\n"
			}
		}

		hwContent := ""
		for i, line := range hwLines {
			hwContent += line
			if i < len(hwLines)-1 {
				hwContent += "\n"
			}
		}

		leftBox := boxStyle.Width(colWidth).Render(sysContent)
		rightBox := boxStyle.Width(colWidth).Render(hwContent)

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
	allContent := ""
	for _, line := range sysLines {
		allContent += line + "\n"
	}
	for i, line := range hwLines {
		allContent += line
		if i < len(hwLines)-1 {
			allContent += "\n"
		}
	}

	singleBox := boxStyle.Width(width - 4).Render(allContent)

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
