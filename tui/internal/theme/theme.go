package theme

// Palette holds the theme colors as hex strings.
type Palette struct {
	Name      string
	Primary   string
	Secondary string
	Muted     string
	Success   string
	Warning   string
	Error     string
	Accent    string
	// UI colors
	Highlight string // Selection highlight background
	Surface   string // Subtle surface background
	Border    string // Active border color
	BorderDim string // Separator / inactive border color
}

var DefaultCyan = Palette{
	Name:      "default",
	Primary:   "#00ffff",
	Secondary: "#0087ff",
	Muted:     "#6c6c6c",
	Success:   "#5fff00",
	Warning:   "#ffaf00",
	Error:     "#ff0000",
	Accent:    "#af87ff",
	Highlight: "#0a1e1e",
	Surface:   "#0a1a1a",
	Border:    "#00ffff",
	BorderDim: "#222222",
}

// Current is the active palette (always DefaultCyan).
var Current = DefaultCyan
