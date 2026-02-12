package theme

// Layout constants for consistent sizing across screens.
const (
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

	// Service table columns
	ServiceColName    = 20
	ServiceColStatus  = 12
	ServiceColEnabled = 10
	ServiceTableWidth = ServiceColName + ServiceColStatus + ServiceColEnabled + 8 // columns + gaps
)
