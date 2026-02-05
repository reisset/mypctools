package bundle

// Bundle describes a script bundle that can be installed/uninstalled.
type Bundle struct {
	ID          string // Directory name under scripts/
	Name        string // Display name
	Description string // Short description
	MarkerPath  string // Path relative to $HOME that indicates installation
}

// All returns the list of all available bundles in display order.
func All() []Bundle {
	return []Bundle{
		{
			ID:          "litebash",
			Name:        "litebash",
			Description: "Speed-focused bash with modern CLI tools",
			MarkerPath:  ".local/share/litebash/litebash.sh",
		},
		{
			ID:          "litezsh",
			Name:        "litezsh",
			Description: "Zsh with syntax highlighting and autosuggestions",
			MarkerPath:  ".local/share/litezsh/litezsh.zsh",
		},
		{
			ID:          "terminal",
			Name:        "foot terminal",
			Description: "foot terminal config (Wayland only)",
			MarkerPath:  ".config/foot/foot.ini",
		},
		{
			ID:          "alacritty",
			Name:        "alacritty",
			Description: "Alacritty terminal config",
			MarkerPath:  ".config/alacritty/alacritty.toml",
		},
		{
			ID:          "ghostty",
			Name:        "ghostty",
			Description: "Ghostty terminal config",
			MarkerPath:  ".config/ghostty/config",
		},
		{
			ID:          "kitty",
			Name:        "kitty",
			Description: "Kitty terminal config",
			MarkerPath:  ".config/kitty/kitty.conf",
		},
		{
			ID:          "fastfetch",
			Name:        "fastfetch",
			Description: "Custom fastfetch with tree-style layout",
			MarkerPath:  ".config/fastfetch/config.jsonc",
		},
		{
			ID:          "screensaver",
			Name:        "screensaver",
			Description: "Terminal screensaver via hypridle + tte",
			MarkerPath:  ".local/bin/mypctools-screensaver-launch",
		},
		{
			ID:          "claude",
			Name:        "claude",
			Description: "Claude Code skills and statusline",
			MarkerPath:  ".claude/statusline.sh",
		},
		{
			ID:          "spicetify",
			Name:        "spicetify",
			Description: "Spotify theming with StarryNight",
			MarkerPath:  ".spicetify/spicetify",
		},
	}
}
