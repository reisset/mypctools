package theme

import "github.com/charmbracelet/lipgloss"

// Style builders derived from the active palette.
// Call these after Load() so they use Current.

func PrimaryStyle() lipgloss.Style {
	return lipgloss.NewStyle().Foreground(lipgloss.Color(Current.Primary))
}

func SecondaryStyle() lipgloss.Style {
	return lipgloss.NewStyle().Foreground(lipgloss.Color(Current.Secondary))
}

func MutedStyle() lipgloss.Style {
	return lipgloss.NewStyle().Foreground(lipgloss.Color(Current.Muted))
}

func SuccessStyle() lipgloss.Style {
	return lipgloss.NewStyle().Foreground(lipgloss.Color(Current.Success))
}

func WarningStyle() lipgloss.Style {
	return lipgloss.NewStyle().Foreground(lipgloss.Color(Current.Warning))
}

func ErrorStyle() lipgloss.Style {
	return lipgloss.NewStyle().Foreground(lipgloss.Color(Current.Error))
}

func AccentStyle() lipgloss.Style {
	return lipgloss.NewStyle().Foreground(lipgloss.Color(Current.Accent))
}

func LogoStyle() lipgloss.Style {
	return lipgloss.NewStyle().
		Foreground(lipgloss.Color(Current.Primary)).
		Align(lipgloss.Center)
}

func SubheaderStyle() lipgloss.Style {
	return lipgloss.NewStyle().
		Foreground(lipgloss.Color(Current.Primary)).
		Border(lipgloss.RoundedBorder()).
		BorderForeground(lipgloss.Color(Current.Secondary)).
		Padding(0, 2)
}

func MenuCursorStyle() lipgloss.Style {
	return lipgloss.NewStyle().Foreground(lipgloss.Color(Current.Primary))
}

func MenuItemStyle() lipgloss.Style {
	return lipgloss.NewStyle().PaddingLeft(2)
}

func MenuSelectedStyle() lipgloss.Style {
	return lipgloss.NewStyle().
		Foreground(lipgloss.Color(Current.Primary)).
		Bold(true).
		PaddingLeft(2)
}

func BadgeInstalledStyle() lipgloss.Style {
	return lipgloss.NewStyle().Foreground(lipgloss.Color(Current.Success))
}
