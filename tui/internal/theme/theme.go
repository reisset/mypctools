package theme

import (
	"os"
	"path/filepath"
	"strings"
)

// Palette holds the 7 theme colors as hex strings.
type Palette struct {
	Name      string
	Primary   string
	Secondary string
	Muted     string
	Success   string
	Warning   string
	Error     string
	Accent    string
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
}

var CatppuccinMocha = Palette{
	Name:      "catppuccin",
	Primary:   "#89b4fa",
	Secondary: "#74c7ec",
	Muted:     "#6c7086",
	Success:   "#a6e3a1",
	Warning:   "#fab387",
	Error:     "#f38ba8",
	Accent:    "#cba6f7",
}

var TokyoNight = Palette{
	Name:      "tokyo-night",
	Primary:   "#7aa2f7",
	Secondary: "#7dcfff",
	Muted:     "#565f89",
	Success:   "#9ece6a",
	Warning:   "#ff9e64",
	Error:     "#f7768e",
	Accent:    "#bb9af7",
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

// Load reads the theme file and sets Current.
func Load() {
	data, err := os.ReadFile(themeFilePath())
	if err != nil {
		Current = DefaultCyan
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
}

// Save writes the theme name to disk.
func Save(name string) error {
	path := themeFilePath()
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		return err
	}
	return os.WriteFile(path, []byte(name+"\n"), 0o644)
}
