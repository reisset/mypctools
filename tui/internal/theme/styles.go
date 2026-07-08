package theme

import "github.com/charmbracelet/lipgloss"

type cachedStyles struct {
	muted   lipgloss.Style
	success lipgloss.Style
	warning lipgloss.Style
	err     lipgloss.Style

	helpKey     lipgloss.Style
	helpDesc    lipgloss.Style
	helpDivider lipgloss.Style
}

var styles cachedStyles

func init() {
	rebuildStyles()
}

// rebuildStyles builds cached styles from Current palette.
func rebuildStyles() {
	styles.muted = lipgloss.NewStyle().Foreground(lipgloss.Color(Current.Muted))
	styles.success = lipgloss.NewStyle().Foreground(lipgloss.Color(Current.Success))
	styles.warning = lipgloss.NewStyle().Foreground(lipgloss.Color(Current.Warning))
	styles.err = lipgloss.NewStyle().Foreground(lipgloss.Color(Current.Error))

	styles.helpKey = lipgloss.NewStyle().
		Foreground(lipgloss.Color(Current.Secondary)).
		Bold(true)

	styles.helpDesc = lipgloss.NewStyle().
		Foreground(lipgloss.Color(Current.Muted))

	styles.helpDivider = lipgloss.NewStyle().
		Foreground(lipgloss.Color(Current.BorderDim))
}

func MutedStyle() lipgloss.Style   { return styles.muted }
func SuccessStyle() lipgloss.Style { return styles.success }
func WarningStyle() lipgloss.Style { return styles.warning }
func ErrorStyle() lipgloss.Style   { return styles.err }

func HelpKeyStyle() lipgloss.Style     { return styles.helpKey }
func HelpDescStyle() lipgloss.Style    { return styles.helpDesc }
func HelpDividerStyle() lipgloss.Style { return styles.helpDivider }
