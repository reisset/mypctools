package pkg

// App represents an installable application.
type App struct {
	ID           string
	Name         string
	Category     string
	AptPkg       string
	PacmanPkg    string
	DnfPkg       string // Fedora package name (if different from AptPkg)
	FlatpakID    string
	CommandCheck string // Binary name to check (e.g., "ollama")
	FallbackCmd  string // Shell command for fallback install
}

// Category constants
const (
	CategoryAI       = "ai"
	CategoryBrowsers = "browsers"
	CategoryGaming   = "gaming"
	CategoryMedia    = "media"
	CategoryDevTools = "devtools"
)

// CategoryInfo holds display metadata for a category.
type CategoryInfo struct {
	ID    string
	Name  string
	Icon  string
	Count int
}

var apps = []App{
	// AI Tools (5)
	{
		ID:           "opencode",
		Name:         "OpenCode",
		Category:     CategoryAI,
		CommandCheck: "opencode",
		FallbackCmd:  "curl -fsSL https://opencode.ai/install | bash",
	},
	{
		ID:           "claude-code",
		Name:         "Claude Code",
		Category:     CategoryAI,
		CommandCheck: "claude",
		FallbackCmd:  "curl -fsSL https://claude.ai/install.sh | bash",
	},
	{
		ID:           "mistral-vibe",
		Name:         "Mistral Vibe",
		Category:     CategoryAI,
		CommandCheck: "vibe",
		FallbackCmd:  "curl -LsSf https://mistral.ai/vibe/install.sh | bash",
	},
	{
		ID:           "ollama",
		Name:         "Ollama",
		Category:     CategoryAI,
		CommandCheck: "ollama",
		FallbackCmd:  "curl -fsSL https://ollama.com/install.sh | sh",
	},
	{
		ID:           "lmstudio",
		Name:         "LM Studio",
		Category:     CategoryAI,
		CommandCheck: "lmstudio",
		FallbackCmd:  "mkdir -p ~/.local/bin && curl -L -o ~/.local/bin/lmstudio.AppImage https://lmstudio.ai/download/latest/linux/x64 && chmod +x ~/.local/bin/lmstudio.AppImage",
	},

	// Browsers (4)
	{
		ID:           "brave",
		Name:         "Brave",
		Category:     CategoryBrowsers,
		PacmanPkg:    "brave-bin",
		FlatpakID:    "com.brave.Browser",
		CommandCheck: "brave",
		FallbackCmd:  "curl -fsS https://dl.brave.com/install.sh | bash",
	},
	{
		ID:           "firefox",
		Name:         "Firefox",
		Category:     CategoryBrowsers,
		AptPkg:       "firefox",
		PacmanPkg:    "firefox",
		DnfPkg:       "firefox",
		FlatpakID:    "org.mozilla.firefox",
		CommandCheck: "firefox",
	},
	{
		ID:           "chromium",
		Name:         "Chromium",
		Category:     CategoryBrowsers,
		AptPkg:       "chromium",
		PacmanPkg:    "chromium",
		DnfPkg:       "chromium",
		FlatpakID:    "org.chromium.Chromium",
		CommandCheck: "chromium",
	},
	{
		ID:           "zen",
		Name:         "Zen Browser",
		Category:     CategoryBrowsers,
		PacmanPkg:    "zen-browser-bin",
		FlatpakID:    "io.github.zen_browser.zen",
		CommandCheck: "zen-browser",
		FallbackCmd:  "curl -fsSL https://github.com/zen-browser/updates-server/raw/refs/heads/main/install.sh | bash",
	},

	// Gaming (4)
	{
		ID:           "steam",
		Name:         "Steam",
		Category:     CategoryGaming,
		AptPkg:       "steam",
		PacmanPkg:    "steam",
		DnfPkg:       "steam",
		FlatpakID:    "com.valvesoftware.Steam",
		CommandCheck: "steam",
	},
	{
		ID:           "lutris",
		Name:         "Lutris",
		Category:     CategoryGaming,
		AptPkg:       "lutris",
		PacmanPkg:    "lutris",
		DnfPkg:       "lutris",
		FlatpakID:    "net.lutris.Lutris",
		CommandCheck: "lutris",
	},
	{
		ID:           "protonup-qt",
		Name:         "ProtonUp-Qt",
		Category:     CategoryGaming,
		FlatpakID:    "net.davidotek.pupgui2",
		CommandCheck: "protonup-qt",
	},
	{
		ID:           "heroic",
		Name:         "Heroic Games Launcher",
		Category:     CategoryGaming,
		PacmanPkg:    "heroic-games-launcher-bin",
		FlatpakID:    "com.heroicgameslauncher.hgl",
		CommandCheck: "heroic",
	},

	// Media (4)
	{
		ID:           "discord",
		Name:         "Discord",
		Category:     CategoryMedia,
		PacmanPkg:    "discord",
		FlatpakID:    "com.discordapp.Discord",
		CommandCheck: "discord",
		FallbackCmd:  "TMP=$(mktemp --suffix=.deb) && curl -fsSL 'https://discord.com/api/download?platform=linux&format=deb' -o $TMP && sudo dpkg -i $TMP && sudo apt-get install -f -y && rm -f $TMP",
	},
	{
		ID:           "spotify",
		Name:         "Spotify",
		Category:     CategoryMedia,
		PacmanPkg:    "spotify-launcher",
		FlatpakID:    "com.spotify.Client",
		CommandCheck: "spotify",
		FallbackCmd:  "curl -sS https://download.spotify.com/debian/pubkey_5384CE82BA52C83A.asc | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg && echo 'deb https://repository.spotify.com stable non-free' | sudo tee /etc/apt/sources.list.d/spotify.list && sudo apt-get update && sudo apt-get install -y spotify-client",
	},
	{
		ID:           "vlc",
		Name:         "VLC",
		Category:     CategoryMedia,
		AptPkg:       "vlc",
		PacmanPkg:    "vlc",
		DnfPkg:       "vlc",
		FlatpakID:    "org.videolan.VLC",
		CommandCheck: "vlc",
	},
	{
		ID:           "mpv",
		Name:         "MPV",
		Category:     CategoryMedia,
		AptPkg:       "mpv",
		PacmanPkg:    "mpv",
		DnfPkg:       "mpv",
		FlatpakID:    "io.mpv.Mpv",
		CommandCheck: "mpv",
	},

	// Dev Tools (8)
	{
		ID:           "docker",
		Name:         "Docker",
		Category:     CategoryDevTools,
		AptPkg:       "docker.io",
		PacmanPkg:    "docker",
		DnfPkg:       "docker",
		CommandCheck: "docker",
	},
	{
		ID:           "docker-compose",
		Name:         "Docker Compose",
		Category:     CategoryDevTools,
		AptPkg:       "docker-compose",
		PacmanPkg:    "docker-compose",
		DnfPkg:       "docker-compose",
		CommandCheck: "docker-compose",
		FallbackCmd:  `VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -Po '"tag_name": "v\K[^"]*') && mkdir -p ~/.docker/cli-plugins && curl -fsSL -o ~/.docker/cli-plugins/docker-compose "https://github.com/docker/compose/releases/download/v${VERSION}/docker-compose-linux-$(uname -m)" && chmod +x ~/.docker/cli-plugins/docker-compose`,
	},
	{
		ID:           "lazydocker",
		Name:         "LazyDocker",
		Category:     CategoryDevTools,
		PacmanPkg:    "lazydocker",
		CommandCheck: "lazydocker",
		FallbackCmd:  `VERSION=$(curl -s https://api.github.com/repos/jesseduffield/lazydocker/releases/latest | grep -Po '"tag_name": "v\K[^"]*') && ARCH=$(uname -m | sed 's/x86_64/x86_64/;s/aarch64/arm64/') && TMP=$(mktemp -d) && curl -fsSL -o "$TMP/lazydocker.tar.gz" "https://github.com/jesseduffield/lazydocker/releases/download/v${VERSION}/lazydocker_${VERSION}_Linux_${ARCH}.tar.gz" && tar -xzf "$TMP/lazydocker.tar.gz" -C "$TMP" && sudo mv "$TMP/lazydocker" /usr/local/bin/ && rm -rf "$TMP"`,
	},
	{
		ID:           "lazygit",
		Name:         "Lazygit",
		Category:     CategoryDevTools,
		PacmanPkg:    "lazygit",
		CommandCheck: "lazygit",
		FallbackCmd:  `VERSION=$(curl -s https://api.github.com/repos/jesseduffield/lazygit/releases/latest | grep -Po '"tag_name": "v\K[^"]*') && ARCH=$(uname -m | sed 's/x86_64/x86_64/;s/aarch64/arm64/') && mkdir -p ~/.local/bin && TMP=$(mktemp -d) && curl -fsSL -o "$TMP/lazygit.tar.gz" "https://github.com/jesseduffield/lazygit/releases/download/v${VERSION}/lazygit_${VERSION}_Linux_${ARCH}.tar.gz" && tar -xzf "$TMP/lazygit.tar.gz" -C "$TMP" && mv "$TMP/lazygit" ~/.local/bin/ && rm -rf "$TMP"`,
	},
	{
		ID:           "vscode",
		Name:         "VS Code",
		Category:     CategoryDevTools,
		PacmanPkg:    "code",
		FlatpakID:    "com.visualstudio.code",
		CommandCheck: "code",
		FallbackCmd:  "wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/microsoft.gpg && sudo install -D -o root -g root -m 644 /tmp/microsoft.gpg /usr/share/keyrings/microsoft.gpg && echo 'deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main' | sudo tee /etc/apt/sources.list.d/vscode.list && sudo apt-get update && sudo apt-get install -y code",
	},
	{
		ID:           "cursor",
		Name:         "Cursor",
		Category:     CategoryDevTools,
		CommandCheck: "cursor",
		FallbackCmd:  "mkdir -p ~/.local/bin && curl -Lo ~/.local/bin/cursor.AppImage https://downloader.cursor.sh/linux/appImage/x64 && chmod +x ~/.local/bin/cursor.AppImage",
	},
	{
		ID:           "dotnet",
		Name:         ".NET SDK",
		Category:     CategoryDevTools,
		AptPkg:       "dotnet-sdk-8.0",
		PacmanPkg:    "dotnet-sdk",
		DnfPkg:       "dotnet-sdk-8.0",
		CommandCheck: "dotnet",
		FallbackCmd:  "sudo apt-get update && sudo apt-get install -y dotnet-sdk-8.0 || (sudo add-apt-repository -y ppa:dotnet/backports && sudo apt-get update && sudo apt-get install -y dotnet-sdk-8.0)",
	},
	{
		ID:           "python",
		Name:         "Python",
		Category:     CategoryDevTools,
		AptPkg:       "python3",
		PacmanPkg:    "python",
		DnfPkg:       "python3",
		CommandCheck: "python3",
	},
}

// AllApps returns all registered apps.
func AllApps() []App {
	return apps
}

// AppsByCategory returns apps for a given category.
func AppsByCategory(category string) []App {
	// Preallocate with estimated capacity (most categories have 4-8 apps)
	result := make([]App, 0, 8)
	for _, a := range apps {
		if a.Category == category {
			result = append(result, a)
		}
	}
	return result
}

// Categories returns all category IDs in display order.
func Categories() []string {
	return []string{
		CategoryAI,
		CategoryBrowsers,
		CategoryGaming,
		CategoryMedia,
		CategoryDevTools,
	}
}

// CategoryDisplayName returns the human-readable name for a category.
func CategoryDisplayName(id string) string {
	switch id {
	case CategoryAI:
		return "AI Tools"
	case CategoryBrowsers:
		return "Browsers"
	case CategoryGaming:
		return "Gaming"
	case CategoryMedia:
		return "Media"
	case CategoryDevTools:
		return "Dev Tools"
	default:
		return id
	}
}

// AppByID returns an app by its ID, or nil if not found.
func AppByID(id string) *App {
	for i := range apps {
		if apps[i].ID == id {
			return &apps[i]
		}
	}
	return nil
}
