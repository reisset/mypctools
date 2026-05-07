package theme

import "github.com/charmbracelet/lipgloss"

type cachedStyles struct {
	primary   lipgloss.Style
	secondary lipgloss.Style
	muted     lipgloss.Style
	success   lipgloss.Style
	warning   lipgloss.Style
	err       lipgloss.Style
	accent    lipgloss.Style

	subheader lipgloss.Style

	helpKey     lipgloss.Style
	helpDesc    lipgloss.Style
	helpDivider lipgloss.Style

	// Status indicators (inline text, no pill background)
	statusActive   lipgloss.Style
	statusInactive lipgloss.Style
	statusError    lipgloss.Style
}

var styles cachedStyles

func init() {
	RebuildStyles()
}

// RebuildStyles rebuilds all cached styles from Current palette.
func RebuildStyles() {
	styles.primary = lipgloss.NewStyle().Foreground(lipgloss.Color(Current.Primary))
	styles.secondary = lipgloss.NewStyle().Foreground(lipgloss.Color(Current.Secondary))
	styles.muted = lipgloss.NewStyle().Foreground(lipgloss.Color(Current.Muted))
	styles.success = lipgloss.NewStyle().Foreground(lipgloss.Color(Current.Success))
	styles.warning = lipgloss.NewStyle().Foreground(lipgloss.Color(Current.Warning))
	styles.err = lipgloss.NewStyle().Foreground(lipgloss.Color(Current.Error))
	styles.accent = lipgloss.NewStyle().Foreground(lipgloss.Color(Current.Accent))

	styles.subheader = lipgloss.NewStyle().
		Foreground(lipgloss.Color(Current.Primary)).
		Bold(true)

	styles.helpKey = lipgloss.NewStyle().
		Foreground(lipgloss.Color(Current.Secondary)).
		Bold(true)

	styles.helpDesc = lipgloss.NewStyle().
		Foreground(lipgloss.Color(Current.Muted))

	styles.helpDivider = lipgloss.NewStyle().
		Foreground(lipgloss.Color(Current.BorderDim))

	styles.statusActive = lipgloss.NewStyle().
		Foreground(lipgloss.Color(Current.Success))

	styles.statusInactive = lipgloss.NewStyle().
		Foreground(lipgloss.Color(Current.Error))

	styles.statusError = lipgloss.NewStyle().
		Foreground(lipgloss.Color(Current.Error))
}

func MutedStyle() lipgloss.Style     { return styles.muted }
func SuccessStyle() lipgloss.Style   { return styles.success }
func WarningStyle() lipgloss.Style   { return styles.warning }
func ErrorStyle() lipgloss.Style     { return styles.err }
func AccentStyle() lipgloss.Style    { return styles.accent }
func SubheaderStyle() lipgloss.Style { return styles.subheader }

func HelpKeyStyle() lipgloss.Style     { return styles.helpKey }
func HelpDescStyle() lipgloss.Style    { return styles.helpDesc }
func HelpDividerStyle() lipgloss.Style { return styles.helpDivider }

func StatusActiveStyle() lipgloss.Style   { return styles.statusActive }
func StatusInactiveStyle() lipgloss.Style { return styles.statusInactive }
func StatusErrorStyle() lipgloss.Style    { return styles.statusError }
