package theme

// Current holds the active theme colors.
// Single palette — the multi-theme picker was removed in v0.36.0.
var Current = struct {
	Primary   string
	Secondary string
	Muted     string
	Success   string
	Warning   string
	Error     string
	Highlight string // Selection highlight background
	Surface   string // Subtle surface background
	Border    string // Active border color
	BorderDim string // Separator / inactive border color
}{
	Primary:   "#00ffff",
	Secondary: "#0087ff",
	Muted:     "#6c6c6c",
	Success:   "#5fff00",
	Warning:   "#ffaf00",
	Error:     "#ff0000",
	Highlight: "#0a1e1e",
	Surface:   "#0a1a1a",
	Border:    "#00ffff",
	BorderDim: "#222222",
}
