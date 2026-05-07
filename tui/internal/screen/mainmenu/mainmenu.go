package mainmenu

import (
	"fmt"
	"os"
	"strings"
	"time"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/reisset/mypctools/tui/internal/app"
	"github.com/reisset/mypctools/tui/internal/screen/pullupdate"
	"github.com/reisset/mypctools/tui/internal/screen/scripts"
	"github.com/reisset/mypctools/tui/internal/screen/systemsetup"
	"github.com/reisset/mypctools/tui/internal/state"
	"github.com/reisset/mypctools/tui/internal/theme"
	"github.com/reisset/mypctools/tui/internal/ui"
)

// logoWord is the text that appears as the main logo.
const logoWord = "MYPCTOOLS"

// logoColors maps each character of logoWord to a gradient color (cyan → blue → purple).
var logoColors = []string{
	"#00ffff", "#00deff", "#00bdff", "#009cff",
	"#0087ff", "#2c87ff", "#5887ff", "#8387ff", "#af87ff",
}

type menuItem struct {
	icon      string
	label     string
	id        string
	separator bool
}

type logoRevealMsg struct{}

const (
	logoRevealChars    = len(logoWord) // reveal one char per tick
	logoRevealInterval = 60 * time.Millisecond
)

// Model is the main menu screen.
type Model struct {
	shared          *state.Shared
	items           []menuItem
	cursor          int
	lastUpdateCount int
	revealProgress  int  // 0..logoRevealChars = animating, -1 = done
	hasAnimated     bool // prevents re-animating on PopScreen
}

func New(shared *state.Shared) Model {
	m := Model{
		shared:          shared,
		cursor:          0,
		lastUpdateCount: -1,
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
		{icon: "◆", label: "My Scripts", id: "scripts"},
		{icon: "⚙", label: "System Setup", id: "system"},
	}
	if m.shared.UpdateCount > 0 {
		m.items = append(m.items, menuItem{
			icon:  "⟳",
			label: fmt.Sprintf("Pull Updates (%d new)", m.shared.UpdateCount),
			id:    "update",
		})
	}
	m.items = append(m.items, menuItem{separator: true})
	m.items = append(m.items, menuItem{icon: "→", label: "Exit", id: "exit"})
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
		if m.revealProgress >= 0 && m.revealProgress < logoRevealChars {
			m.revealProgress++
			if m.revealProgress >= logoRevealChars {
				m.revealProgress = -1
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
		case "q":
			return m, tea.Quit
		case "down":
			for range len(m.items) {
				m.cursor++
				if m.cursor >= len(m.items) {
					m.cursor = 0
				}
				if !m.items[m.cursor].separator {
					break
				}
			}
		case "up":
			for range len(m.items) {
				m.cursor--
				if m.cursor < 0 {
					m.cursor = len(m.items) - 1
				}
				if !m.items[m.cursor].separator {
					break
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
	height := m.shared.TerminalHeight
	if height == 0 {
		height = 24
	}

	hideLogo := height < 18
	hideInfo := height < 14

	items := make([]ui.ListItem, len(m.items))
	for i, item := range m.items {
		items[i] = ui.ListItem{
			Icon:      item.icon,
			Label:     item.label,
			Separator: item.separator,
		}
	}

	menu := ui.RenderList(items, m.cursor, ui.ListConfig{
		Width:         56,
		MaxInnerWidth: 56,
	})

	menuBlock := lipgloss.NewStyle().
		Width(width).
		Align(lipgloss.Center).
		Render(menu)

	var parts []string

	if !hideLogo {
		parts = append(parts, renderLogo(m.revealProgress, width))
	}

	if !hideInfo {
		sysLine := buildSysLine(m.shared)
		sysLineRendered := lipgloss.NewStyle().
			Foreground(lipgloss.Color(theme.Current.Muted)).
			Width(width).
			Align(lipgloss.Center).
			Render(sysLine)
		parts = append(parts, sysLineRendered)
	}

	parts = append(parts, "", menuBlock)

	return lipgloss.JoinVertical(lipgloss.Left, parts...)
}

func (m Model) Title() string {
	return "Main Menu"
}

func (m Model) ShortHelp() []string {
	return []string{"↑↓ navigate", "enter select", "q quit"}
}

// renderLogo renders "MYPCTOOLS" with per-character gradient and letter-spacing.
// revealProgress -1 = fully visible; 0..8 = revealing left-to-right.
func renderLogo(revealProgress, width int) string {
	chars := []rune(logoWord)
	revealed := len(chars)
	if revealProgress >= 0 {
		revealed = revealProgress
	}

	var sb strings.Builder
	for i, ch := range chars {
		color := logoColors[i]
		if i >= revealed {
			// Not yet revealed — render as a blank space
			sb.WriteString(" ")
		} else {
			styled := lipgloss.NewStyle().
				Foreground(lipgloss.Color(color)).
				Bold(true).
				Render(string(ch))
			sb.WriteString(styled)
		}
		// Letter-spacing: double space between characters for presence
		if i < len(chars)-1 {
			sb.WriteString("  ")
		}
	}

	return lipgloss.NewStyle().
		Width(width).
		Align(lipgloss.Center).
		Render(sb.String())
}

func buildSysLine(shared *state.Shared) string {
	shell := os.Getenv("SHELL")
	if shell != "" {
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

	sep := "  " + theme.Icons.Dot + "  "
	parts := []string{theme.Icons.Distro + " " + shared.Distro.Name}
	if kernel != "" {
		parts = append(parts, theme.Icons.Kernel+" "+kernel)
	}
	parts = append(parts, theme.Icons.Shell+" "+shell)

	return strings.Join(parts, sep)
}
