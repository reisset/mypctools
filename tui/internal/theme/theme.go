package theme

import (
	"os"
	"path/filepath"
	"strings"
)

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
	BorderDim string // Inactive border color
	// Logo gradient (6 colors for 6-line logo; compact 3-line uses [0],[2],[4])
	LogoGradient []string
}

var DefaultCyan = Palette{
	Name:         "default",
	Primary:      "#00ffff",
	Secondary:    "#0087ff",
	Muted:        "#6c6c6c",
	Success:      "#5fff00",
	Warning:      "#ffaf00",
	Error:        "#ff0000",
	Accent:       "#af87ff",
	Highlight:    "#004d4d",
	Surface:      "#0a1a1a",
	Border:       "#0087ff",
	BorderDim:    "#3c3c3c",
	LogoGradient: []string{"#00ffff", "#00d7ff", "#00afff", "#0087ff", "#5f87ff", "#af87ff"},
}

var CatppuccinMocha = Palette{
	Name:         "catppuccin",
	Primary:      "#89b4fa",
	Secondary:    "#74c7ec",
	Muted:        "#6c7086",
	Success:      "#a6e3a1",
	Warning:      "#fab387",
	Error:        "#f38ba8",
	Accent:       "#cba6f7",
	Highlight:    "#313244",
	Surface:      "#181825",
	Border:       "#89b4fa",
	BorderDim:    "#45475a",
	LogoGradient: []string{"#89b4fa", "#89a8f7", "#9b9ef5", "#a994f2", "#b78bf0", "#cba6f7"},
}

var TokyoNight = Palette{
	Name:         "tokyo-night",
	Primary:      "#c0caf5",
	Secondary:    "#bb9af7",
	Muted:        "#565f89",
	Success:      "#9ece6a",
	Warning:      "#ff9e64",
	Error:        "#f7768e",
	Accent:       "#7dcfff",
	Highlight:    "#292e42",
	Surface:      "#16161e",
	Border:       "#c0caf5",
	BorderDim:    "#414868",
	LogoGradient: []string{"#c0caf5", "#b4b8f0", "#a8a6eb", "#bb9af7", "#9db8e0", "#7dcfff"},
}

var Dracula = Palette{
	Name:         "dracula",
	Primary:      "#f8f8f2",
	Secondary:    "#bd93f9",
	Muted:        "#6272a4",
	Success:      "#50fa7b",
	Warning:      "#ffb86c",
	Error:        "#ff5555",
	Accent:       "#ff79c6",
	Highlight:    "#44475a",
	Surface:      "#282a36",
	Border:       "#bd93f9",
	BorderDim:    "#44475a",
	LogoGradient: []string{"#ff79c6", "#e48cde", "#cc9df0", "#bd93f9", "#9cb3fc", "#8be9fd"},
}

var Nord = Palette{
	Name:         "nord",
	Primary:      "#eceff4",
	Secondary:    "#88c0d0",
	Muted:        "#4c566a",
	Success:      "#a3be8c",
	Warning:      "#ebcb8b",
	Error:        "#bf616a",
	Accent:       "#b48ead",
	Highlight:    "#3b4252",
	Surface:      "#2e3440",
	Border:       "#88c0d0",
	BorderDim:    "#434c5e",
	LogoGradient: []string{"#8fbcbb", "#88c0d0", "#81a1c1", "#5e81ac", "#7b9fbd", "#b48ead"},
}

var GruvboxDark = Palette{
	Name:         "gruvbox",
	Primary:      "#ebdbb2",
	Secondary:    "#fe8019",
	Muted:        "#665c54",
	Success:      "#b8bb26",
	Warning:      "#fabd2f",
	Error:        "#fb4934",
	Accent:       "#d3869b",
	Highlight:    "#3c3836",
	Surface:      "#282828",
	Border:       "#fe8019",
	BorderDim:    "#504945",
	LogoGradient: []string{"#fb4934", "#fe8019", "#fabd2f", "#b8bb26", "#8ec07c", "#83a598"},
}

var RosePine = Palette{
	Name:         "rose-pine",
	Primary:      "#e0def4",
	Secondary:    "#c4a7e7",
	Muted:        "#6e6a86",
	Success:      "#9ccfd8",
	Warning:      "#f6c177",
	Error:        "#eb6f92",
	Accent:       "#ebbcba",
	Highlight:    "#26233a",
	Surface:      "#191724",
	Border:       "#c4a7e7",
	BorderDim:    "#403d52",
	LogoGradient: []string{"#eb6f92", "#ebbcba", "#f6c177", "#9ccfd8", "#c4a7e7", "#e0def4"},
}

// All available presets.
var Presets = []Palette{DefaultCyan, CatppuccinMocha, TokyoNight, Dracula, Nord, GruvboxDark, RosePine}

// Current is the active palette. Set via Load().
var Current = DefaultCyan

// themeFilePath returns ~/.config/mypctools/theme.
func themeFilePath() string {
	home, _ := os.UserHomeDir()
	return filepath.Join(home, ".config", "mypctools", "theme")
}

// Load reads the theme file and sets Current, then rebuilds cached styles.
func Load() {
	data, err := os.ReadFile(themeFilePath())
	if err != nil {
		Current = DefaultCyan
		RebuildStyles()
		return
	}
	name := strings.TrimSpace(string(data))
	switch name {
	case "catppuccin":
		Current = CatppuccinMocha
	case "tokyo-night":
		Current = TokyoNight
	case "dracula":
		Current = Dracula
	case "nord":
		Current = Nord
	case "gruvbox":
		Current = GruvboxDark
	case "rose-pine":
		Current = RosePine
	default:
		Current = DefaultCyan
	}
	RebuildStyles()
}

// Save writes the theme name to disk.
func Save(name string) error {
	path := themeFilePath()
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		return err
	}
	return os.WriteFile(path, []byte(name+"\n"), 0o644)
}
