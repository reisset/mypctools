package theme

import "github.com/charmbracelet/lipgloss"

// cachedStyles holds pre-built styles to avoid recreation on every call.
type cachedStyles struct {
	primary        lipgloss.Style
	secondary      lipgloss.Style
	muted          lipgloss.Style
	success        lipgloss.Style
	warning        lipgloss.Style
	err            lipgloss.Style
	accent         lipgloss.Style
	logo           lipgloss.Style
	subheader      lipgloss.Style
	menuCursor     lipgloss.Style
	menuItem       lipgloss.Style
	menuSelected   lipgloss.Style
	badgeInstalled lipgloss.Style
}

var styles cachedStyles

func init() {
	RebuildStyles()
}

// RebuildStyles rebuilds all cached styles from Current palette.
// Call this after changing the theme.
func RebuildStyles() {
	styles.primary = lipgloss.NewStyle().Foreground(lipgloss.Color(Current.Primary))
	styles.secondary = lipgloss.NewStyle().Foreground(lipgloss.Color(Current.Secondary))
	styles.muted = lipgloss.NewStyle().Foreground(lipgloss.Color(Current.Muted))
	styles.success = lipgloss.NewStyle().Foreground(lipgloss.Color(Current.Success))
	styles.warning = lipgloss.NewStyle().Foreground(lipgloss.Color(Current.Warning))
	styles.err = lipgloss.NewStyle().Foreground(lipgloss.Color(Current.Error))
	styles.accent = lipgloss.NewStyle().Foreground(lipgloss.Color(Current.Accent))
	styles.logo = lipgloss.NewStyle().
		Foreground(lipgloss.Color(Current.Primary)).
		Align(lipgloss.Center)
	styles.subheader = lipgloss.NewStyle().
		Foreground(lipgloss.Color(Current.Primary)).
		Border(lipgloss.RoundedBorder()).
		BorderForeground(lipgloss.Color(Current.Secondary)).
		Padding(0, 2)
	styles.menuCursor = lipgloss.NewStyle().Foreground(lipgloss.Color(Current.Primary))
	styles.menuItem = lipgloss.NewStyle().PaddingLeft(2)
	styles.menuSelected = lipgloss.NewStyle().
		Foreground(lipgloss.Color(Current.Primary)).
		Bold(true).
		PaddingLeft(2)
	styles.badgeInstalled = lipgloss.NewStyle().Foreground(lipgloss.Color(Current.Success))
}

// Style accessors return cached styles.

func PrimaryStyle() lipgloss.Style {
	return styles.primary
}

func SecondaryStyle() lipgloss.Style {
	return styles.secondary
}

func MutedStyle() lipgloss.Style {
	return styles.muted
}

func SuccessStyle() lipgloss.Style {
	return styles.success
}

func WarningStyle() lipgloss.Style {
	return styles.warning
}

func ErrorStyle() lipgloss.Style {
	return styles.err
}

func AccentStyle() lipgloss.Style {
	return styles.accent
}

func LogoStyle() lipgloss.Style {
	return styles.logo
}

func SubheaderStyle() lipgloss.Style {
	return styles.subheader
}

func MenuCursorStyle() lipgloss.Style {
	return styles.menuCursor
}

func MenuItemStyle() lipgloss.Style {
	return styles.menuItem
}

func MenuSelectedStyle() lipgloss.Style {
	return styles.menuSelected
}

func BadgeInstalledStyle() lipgloss.Style {
	return styles.badgeInstalled
}
