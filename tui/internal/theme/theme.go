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

// All available presets.
var Presets = []Palette{DefaultCyan, CatppuccinMocha, TokyoNight}

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
