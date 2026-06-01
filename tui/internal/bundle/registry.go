package bundle

// Bundle describes a script bundle that can be installed/uninstalled.
type Bundle struct {
	ID             string // Directory name under scripts/
	Name           string // Display name
	Description    string // Short description
	PlatformSuffix string // Platform hint shown in the list (e.g. "arch", "hyprland")
	MarkerPath     string // Path relative to $HOME that indicates installation
	AutoSync       bool   // Re-run install.sh automatically after a repo update (config-only bundles only)
}

// All returns the list of all available bundles in display order.
func All() []Bundle {
	return []Bundle{
		{
			ID:          "litebash",
			Name:        "LiteBash",
			Description: "bash with modern CLI tools (eza, bat, ripgrep, fd, zoxide)",
			MarkerPath:  ".local/share/litebash/litebash.sh",
		},
		{
			ID:          "litezsh",
			Name:        "LiteZsh",
			Description: "zsh with syntax highlighting and autosuggestions",
			MarkerPath:  ".local/share/litezsh/litezsh.zsh",
		},
		{
			ID:          "alacritty",
			Name:        "Alacritty",
			Description: "X11/Wayland terminal config",
			MarkerPath:  ".config/alacritty/alacritty.toml",
			AutoSync:    true,
		},
		{
			ID:          "kitty",
			Name:        "Kitty",
			Description: "X11/Wayland terminal config",
			MarkerPath:  ".config/kitty/kitty.conf",
			AutoSync:    true,
		},
		{
			ID:          "fastfetch",
			Name:        "Fastfetch",
			Description: "tree-style layout with nerd font icons",
			MarkerPath:  ".config/fastfetch/config.jsonc",
			AutoSync:    true,
		},
		{
			ID:             "screensaver",
			Name:           "Screensaver",
			Description:    "terminal screensaver via hypridle + tte",
			PlatformSuffix: "hyprland",
			MarkerPath:     ".local/bin/mypctools-screensaver-launch",
		},
		{
			ID:             "gnome-ubuntu",
			Name:           "GNOME Ubuntu",
			Description:    "Ubuntu GNOME defaults for Arch",
			PlatformSuffix: "arch",
			MarkerPath:     ".local/share/gnome-ubuntu/installed",
		},
		{
			ID:          "claude",
			Name:        "Claude",
			Description: "Claude Code skills and statusline",
			MarkerPath:  ".claude/statusline.sh",
			AutoSync:    true,
		},
		{
			ID:          "spicetify",
			Name:        "Spicetify",
			Description: "StarryNight theme for Spotify",
			MarkerPath:  ".config/spicetify/config-xpui.ini",
		},
	}
}
