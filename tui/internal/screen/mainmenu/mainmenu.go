package mainmenu

import (
	"fmt"
	"os"
	"strings"
	"time"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/reisset/mypctools/tui/internal/app"

	"github.com/reisset/mypctools/tui/internal/screen/apps"
	"github.com/reisset/mypctools/tui/internal/screen/pullupdate"
	"github.com/reisset/mypctools/tui/internal/screen/scripts"
	"github.com/reisset/mypctools/tui/internal/screen/systemsetup"
	"github.com/reisset/mypctools/tui/internal/state"
	"github.com/reisset/mypctools/tui/internal/theme"
	"github.com/reisset/mypctools/tui/internal/ui"
)

const logo = `███╗   ███╗██╗   ██╗██████╗  ██████╗████████╗ ██████╗  ██████╗ ██╗     ███████╗
████╗ ████║╚██╗ ██╔╝██╔══██╗██╔════╝╚══██╔══╝██╔═══██╗██╔═══██╗██║     ██╔════╝
██╔████╔██║ ╚████╔╝ ██████╔╝██║        ██║   ██║   ██║██║   ██║██║     ███████╗
██║╚██╔╝██║  ╚██╔╝  ██╔═══╝ ██║        ██║   ██║   ██║██║   ██║██║     ╚════██║
██║ ╚═╝ ██║   ██║   ██║     ╚██████╗   ██║   ╚██████╔╝╚██████╔╝███████╗███████║
╚═╝     ╚═╝   ╚═╝   ╚═╝      ╚═════╝   ╚═╝    ╚═════╝  ╚═════╝ ╚══════╝╚══════╝`

// Compact logo for narrow terminals
const logoCompact = `╔╦╗╦ ╦╔═╗╔═╗╔╦╗╔═╗╔═╗╦  ╔═╗
║║║╚╦╝╠═╝║   ║ ║ ║║ ║║  ╚═╗
╩ ╩ ╩ ╩  ╚═╝ ╩ ╚═╝╚═╝╩═╝╚═╝`

type menuItem struct {
	icon      string
	label     string
	id        string
	separator bool
}

// Logo reveal animation
type logoRevealMsg struct{}

const (
	logoRevealTicks    = 8
	logoRevealInterval = 50 * time.Millisecond
)

// Model is the main menu screen.
type Model struct {
	shared          *state.Shared
	items           []menuItem
	cursor          int
	lastUpdateCount int
	revealProgress  int  // 0..logoRevealTicks = animating, -1 = done
	hasAnimated     bool // Prevents re-animating on PopScreen
}

func New(shared *state.Shared) Model {
	m := Model{
		shared:          shared,
		cursor:          0,
		lastUpdateCount: -1, // Force initial build
	}
	m.rebuildItemsIfNeeded()
	return m
}

func (m *Model) rebuildItemsIfNeeded() {
	if m.lastUpdateCount == m.shared.UpdateCount {
		return
	}
	m.lastUpdateCount = m.shared.UpdateCount
	m.items = []menuItem{
		{icon: theme.Icons.Apps, label: "Install Apps", id: "apps"},
		{icon: theme.Icons.Scripts, label: "My Scripts", id: "scripts"},
		{icon: theme.Icons.System, label: "System Setup", id: "system"},
	}
	if m.shared.UpdateCount > 0 {
		m.items = append(m.items, menuItem{
			icon:  theme.Icons.Update,
			label: fmt.Sprintf("Pull Updates (%d new)", m.shared.UpdateCount),
			id:    "update",
		})
	}
	m.items = append(m.items, menuItem{separator: true})
	m.items = append(m.items, menuItem{icon: theme.Icons.Exit, label: "Exit", id: "exit"})
	if m.cursor >= len(m.items) {
		m.cursor = len(m.items) - 1
	}
}

func (m Model) Init() tea.Cmd {
	if m.hasAnimated {
		return nil
	}
	return tea.Tick(logoRevealInterval, func(t time.Time) tea.Msg {
		return logoRevealMsg{}
	})
}

func (m Model) Update(msg tea.Msg) (app.Screen, tea.Cmd) {
	m.rebuildItemsIfNeeded()

	switch msg := msg.(type) {
	case logoRevealMsg:
		if m.revealProgress >= 0 && m.revealProgress < logoRevealTicks {
			m.revealProgress++
			if m.revealProgress >= logoRevealTicks {
				m.revealProgress = -1 // Done
				m.hasAnimated = true
				return m, nil
			}
			return m, tea.Tick(logoRevealInterval, func(t time.Time) tea.Msg {
				return logoRevealMsg{}
			})
		}
		return m, nil

	case tea.KeyMsg:
		switch msg.String() {
		case "down", "j":
			m.cursor++
			if m.cursor >= len(m.items) {
				m.cursor = 0
			}
			if m.items[m.cursor].separator {
				m.cursor++
				if m.cursor >= len(m.items) {
					m.cursor = 0
				}
			}
		case "up", "k":
			m.cursor--
			if m.cursor < 0 {
				m.cursor = len(m.items) - 1
			}
			if m.items[m.cursor].separator {
				m.cursor--
				if m.cursor < 0 {
					m.cursor = len(m.items) - 1
				}
			}
		case "enter", " ":
			if m.cursor < len(m.items) && !m.items[m.cursor].separator {
				return m, m.handleSelection(m.items[m.cursor].id)
			}
		}
	}
	return m, nil
}

func (m Model) handleSelection(id string) tea.Cmd {
	switch id {
	case "exit":
		return tea.Quit
	case "apps":
		return app.Navigate(apps.New(m.shared))
	case "scripts":
		return app.Navigate(scripts.New(m.shared))
	case "system":
		return app.Navigate(systemsetup.New(m.shared))
	case "update":
		return app.Navigate(pullupdate.New(m.shared))
	}
	return nil
}

func (m Model) View() string {
	width := m.shared.TerminalWidth
	if width == 0 {
		width = 80
	}

	// Choose logo based on width and apply gradient
	currentLogo := logo
	compact := width < theme.MainMenuLogoBreak
	if compact {
		currentLogo = logoCompact
	}

	revealFrac := 1.0
	if m.revealProgress >= 0 {
		revealFrac = float64(m.revealProgress) / float64(logoRevealTicks)
	}
	renderedLogo := renderGradientLogo(currentLogo, compact, width, revealFrac)

	// Update badge
	var updateBadge string
	if m.shared.UpdateCount > 0 {
		updateBadge = lipgloss.NewStyle().
			Foreground(lipgloss.Color(theme.Current.Accent)).
			Width(width).
			Align(lipgloss.Center).
			Render(fmt.Sprintf("%s Update available (%d new)", theme.Icons.Update, m.shared.UpdateCount))
	}

	// System info line with better spacing
	sysLine := buildSysLine(m.shared)
	sysLineRendered := lipgloss.NewStyle().
		Foreground(lipgloss.Color(theme.Current.Muted)).
		Width(width).
		Align(lipgloss.Center).
		Render(sysLine)

	// Menu items using new list component
	items := make([]ui.ListItem, len(m.items))
	for i, item := range m.items {
		items[i] = ui.ListItem{
			Icon:      item.icon,
			Label:     item.label,
			Separator: item.separator,
		}
	}

	menu := ui.RenderList(items, m.cursor, ui.ListConfig{
		Width:         width,
		ShowCursor:    true,
		HighlightFull: true,
	})

	// Wrap menu in a box with active border
	menuBox := ui.Box(menu, ui.BoxConfig{
		Width:  theme.MainMenuBoxWidth,
		Active: true,
	})

	// Center the menu
	menuBlock := lipgloss.NewStyle().
		Width(width).
		Align(lipgloss.Center).
		Render(menuBox)

	// Tagline below system info
	tagline := lipgloss.NewStyle().
		Foreground(lipgloss.Color(theme.Current.Muted)).
		Width(width).
		Align(lipgloss.Center).
		Render("linux toolkit")

	parts := []string{renderedLogo}
	if updateBadge != "" {
		parts = append(parts, updateBadge)
	}
	parts = append(parts, sysLineRendered, tagline, "", menuBlock)

	return lipgloss.JoinVertical(lipgloss.Left, parts...)
}

func (m Model) Title() string {
	return "Main Menu"
}

func (m Model) ShortHelp() []string {
	return []string{"enter select"}
}

func renderGradientLogo(logoText string, compact bool, width int, revealFrac float64) string {
	lines := strings.Split(logoText, "\n")
	gradient := theme.Current.LogoGradient

	// Apply reveal mask: replace unrevealed characters with spaces
	if revealFrac < 1.0 {
		totalChars := 0
		for _, line := range lines {
			totalChars += len([]rune(line))
		}
		revealCount := int(float64(totalChars) * revealFrac)

		charsSoFar := 0
		for i, line := range lines {
			runes := []rune(line)
			for j := range runes {
				if charsSoFar >= revealCount {
					runes[j] = ' '
				}
				charsSoFar++
			}
			lines[i] = string(runes)
		}
	}

	if len(gradient) == 0 {
		// Fallback: single color
		text := strings.Join(lines, "\n")
		return lipgloss.NewStyle().
			Foreground(lipgloss.Color(theme.Current.Primary)).
			Width(width).
			Align(lipgloss.Center).
			Render(text)
	}

	var coloredLines []string
	for i, line := range lines {
		// Map line index to gradient color
		var colorIdx int
		if compact {
			// 3-line logo: use colors[0], colors[2], colors[4]
			colorIdx = i * 2
		} else {
			colorIdx = i
		}
		if colorIdx >= len(gradient) {
			colorIdx = len(gradient) - 1
		}

		styled := lipgloss.NewStyle().
			Foreground(lipgloss.Color(gradient[colorIdx])).
			Render(line)
		coloredLines = append(coloredLines, styled)
	}

	joined := strings.Join(coloredLines, "\n")
	return lipgloss.NewStyle().
		Width(width).
		Align(lipgloss.Center).
		Render(joined)
}

func buildSysLine(shared *state.Shared) string {
	shell := os.Getenv("SHELL")
	if shell != "" {
		// Extract just the shell name
		parts := strings.Split(shell, "/")
		shell = parts[len(parts)-1]
	} else {
		shell = "sh"
	}

	kernel := ""
	if data, err := os.ReadFile("/proc/version"); err == nil {
		fields := strings.Fields(string(data))
		if len(fields) >= 3 {
			kernel = fields[2]
		}
	}

	// Build with icons and dot separators
	sep := "  " + theme.Icons.Dot + "  "
	parts := []string{theme.Icons.Distro + " " + shared.Distro.Name}
	if kernel != "" {
		parts = append(parts, theme.Icons.Kernel+" "+kernel)
	}
	parts = append(parts, theme.Icons.Shell+" "+shell)

	return strings.Join(parts, sep)
}
