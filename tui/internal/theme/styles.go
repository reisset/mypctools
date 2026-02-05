package theme

import "github.com/charmbracelet/lipgloss"

// cachedStyles holds pre-built styles to avoid recreation on every call.
type cachedStyles struct {
	// Base color styles
	primary   lipgloss.Style
	secondary lipgloss.Style
	muted     lipgloss.Style
	success   lipgloss.Style
	warning   lipgloss.Style
	err       lipgloss.Style
	accent    lipgloss.Style

	// Component styles
	logo           lipgloss.Style
	subheader      lipgloss.Style
	menuCursor     lipgloss.Style
	menuItem       lipgloss.Style
	menuSelected   lipgloss.Style
	badgeInstalled lipgloss.Style

	// Full-width highlight bar styles (new)
	listHighlight lipgloss.Style
	listNormal    lipgloss.Style
	listDimmed    lipgloss.Style

	// Box/card styles (btop-inspired)
	box        lipgloss.Style
	boxActive  lipgloss.Style
	boxTitle   lipgloss.Style
	boxContent lipgloss.Style

	// Table styles
	tableHeader      lipgloss.Style
	tableRow         lipgloss.Style
	tableRowSelected lipgloss.Style

	// Status badges (pill style)
	statusActive   lipgloss.Style
	statusInactive lipgloss.Style
	statusError    lipgloss.Style

	// Footer/help styles
	helpKey     lipgloss.Style
	helpDesc    lipgloss.Style
	helpDivider lipgloss.Style
}

var styles cachedStyles

func init() {
	RebuildStyles()
}

// RebuildStyles rebuilds all cached styles from Current palette.
// Call this after changing the theme.
func RebuildStyles() {
	// Base color styles
	styles.primary = lipgloss.NewStyle().Foreground(lipgloss.Color(Current.Primary))
	styles.secondary = lipgloss.NewStyle().Foreground(lipgloss.Color(Current.Secondary))
	styles.muted = lipgloss.NewStyle().Foreground(lipgloss.Color(Current.Muted))
	styles.success = lipgloss.NewStyle().Foreground(lipgloss.Color(Current.Success))
	styles.warning = lipgloss.NewStyle().Foreground(lipgloss.Color(Current.Warning))
	styles.err = lipgloss.NewStyle().Foreground(lipgloss.Color(Current.Error))
	styles.accent = lipgloss.NewStyle().Foreground(lipgloss.Color(Current.Accent))

	// Logo
	styles.logo = lipgloss.NewStyle().
		Foreground(lipgloss.Color(Current.Primary)).
		Align(lipgloss.Center)

	// Subheader (inline style, no box)
	styles.subheader = lipgloss.NewStyle().
		Foreground(lipgloss.Color(Current.Primary)).
		Bold(true)

	// Menu cursor and items
	styles.menuCursor = lipgloss.NewStyle().Foreground(lipgloss.Color(Current.Primary))
	styles.menuItem = lipgloss.NewStyle().PaddingLeft(PadItemH)
	styles.menuSelected = lipgloss.NewStyle().
		Foreground(lipgloss.Color(Current.Primary)).
		Bold(true).
		PaddingLeft(PadItemH)
	styles.badgeInstalled = lipgloss.NewStyle().Foreground(lipgloss.Color(Current.Success))

	// Full-width highlight bar for selected items
	styles.listHighlight = lipgloss.NewStyle().
		Background(lipgloss.Color(Current.Highlight)).
		Foreground(lipgloss.Color(Current.Primary)).
		Bold(true).
		Padding(0, PadItemH)

	styles.listNormal = lipgloss.NewStyle().
		Foreground(lipgloss.Color(Current.Primary)).
		Padding(0, PadItemH)

	styles.listDimmed = lipgloss.NewStyle().
		Foreground(lipgloss.Color(Current.Muted)).
		Padding(0, PadItemH)

	// btop-inspired boxes
	styles.box = lipgloss.NewStyle().
		Border(lipgloss.RoundedBorder()).
		BorderForeground(lipgloss.Color(Current.BorderDim)).
		Padding(PadBoxV, PadBoxH)

	styles.boxActive = lipgloss.NewStyle().
		Border(lipgloss.RoundedBorder()).
		BorderForeground(lipgloss.Color(Current.Border)).
		Padding(PadBoxV, PadBoxH)

	styles.boxTitle = lipgloss.NewStyle().
		Foreground(lipgloss.Color(Current.Primary)).
		Bold(true)

	styles.boxContent = lipgloss.NewStyle().
		Foreground(lipgloss.Color(Current.Primary))

	// Table styles
	styles.tableHeader = lipgloss.NewStyle().
		Foreground(lipgloss.Color(Current.Muted)).
		Bold(true)

	styles.tableRow = lipgloss.NewStyle().
		Foreground(lipgloss.Color(Current.Primary))

	styles.tableRowSelected = lipgloss.NewStyle().
		Background(lipgloss.Color(Current.Highlight)).
		Foreground(lipgloss.Color(Current.Primary)).
		Bold(true)

	// Status badges (pill style)
	styles.statusActive = lipgloss.NewStyle().
		Background(lipgloss.Color(Current.Success)).
		Foreground(lipgloss.Color("#000000")).
		Padding(0, 1)

	styles.statusInactive = lipgloss.NewStyle().
		Foreground(lipgloss.Color(Current.Muted))

	styles.statusError = lipgloss.NewStyle().
		Background(lipgloss.Color(Current.Error)).
		Foreground(lipgloss.Color("#ffffff")).
		Padding(0, 1)

	// Footer/help styles
	styles.helpKey = lipgloss.NewStyle().
		Foreground(lipgloss.Color(Current.Secondary)).
		Bold(true)

	styles.helpDesc = lipgloss.NewStyle().
		Foreground(lipgloss.Color(Current.Muted))

	styles.helpDivider = lipgloss.NewStyle().
		Foreground(lipgloss.Color(Current.BorderDim))
}

// Style accessors return cached styles.

func PrimaryStyle() lipgloss.Style   { return styles.primary }
func SecondaryStyle() lipgloss.Style { return styles.secondary }
func MutedStyle() lipgloss.Style     { return styles.muted }
func SuccessStyle() lipgloss.Style   { return styles.success }
func WarningStyle() lipgloss.Style   { return styles.warning }
func ErrorStyle() lipgloss.Style     { return styles.err }
func AccentStyle() lipgloss.Style    { return styles.accent }

func LogoStyle() lipgloss.Style         { return styles.logo }
func SubheaderStyle() lipgloss.Style    { return styles.subheader }
func MenuCursorStyle() lipgloss.Style   { return styles.menuCursor }
func MenuItemStyle() lipgloss.Style     { return styles.menuItem }
func MenuSelectedStyle() lipgloss.Style { return styles.menuSelected }
func BadgeInstalledStyle() lipgloss.Style { return styles.badgeInstalled }

// New style accessors
func ListHighlightStyle() lipgloss.Style { return styles.listHighlight }
func ListNormalStyle() lipgloss.Style    { return styles.listNormal }
func ListDimmedStyle() lipgloss.Style    { return styles.listDimmed }

func BoxStyle() lipgloss.Style        { return styles.box }
func BoxActiveStyle() lipgloss.Style  { return styles.boxActive }
func BoxTitleStyle() lipgloss.Style   { return styles.boxTitle }
func BoxContentStyle() lipgloss.Style { return styles.boxContent }

func TableHeaderStyle() lipgloss.Style      { return styles.tableHeader }
func TableRowStyle() lipgloss.Style         { return styles.tableRow }
func TableRowSelectedStyle() lipgloss.Style { return styles.tableRowSelected }

func StatusActiveStyle() lipgloss.Style   { return styles.statusActive }
func StatusInactiveStyle() lipgloss.Style { return styles.statusInactive }
func StatusErrorStyle() lipgloss.Style    { return styles.statusError }

func HelpKeyStyle() lipgloss.Style     { return styles.helpKey }
func HelpDescStyle() lipgloss.Style    { return styles.helpDesc }
func HelpDividerStyle() lipgloss.Style { return styles.helpDivider }
