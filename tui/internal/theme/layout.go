package theme

// ClampBoxWidth returns the smaller of preferred and termWidth-4, with a minimum of 10.
// Use this in screen View() methods to prevent box overflow on narrow terminals.
func ClampBoxWidth(preferred, termWidth int) int {
	max := termWidth - 4
	if max < 10 {
		max = 10
	}
	if preferred <= max {
		return preferred
	}
	return max
}

// Layout constants for consistent sizing across screens.
const (
	// Minimum terminal dimensions — below these, the "too small" guard fires.
	MinWidth  = 40
	MinHeight = 10
	// List rendering
	ListWidthDefault  = 60 // Default total width when none provided
	ListInnerWidthMax = 50 // Max content width for menus
	ListCursorWidth   = 3  // Fixed cursor column width
	ListSeparator     = "───"

	// Footer
	FooterDividerMax = 60
	FooterDividerMin = 20
	FooterKeySep     = " │ "

	// Main menu
	MainMenuBoxWidth  = 56
	MainMenuLogoBreak = 85 // Terminal width threshold for compact logo

	// Sub-menu boxes
	SubMenuBoxWidth = 64 // Standard sub-menu box width
	WideBoxWidth    = 84 // Wide box for scripts/app list (descriptions/badges)

	// Service table columns
	ServiceColName    = 20
	ServiceColStatus  = 12
	ServiceColEnabled = 10
	ServiceTableWidth = ServiceColName + ServiceColStatus + ServiceColEnabled + 8 // columns + gaps
)
