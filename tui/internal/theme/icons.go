package theme

import (
	"os"
	"sync"
)

var iconsMu sync.RWMutex

// Icon pairs: nerd font glyph + ASCII fallback.
type IconSet struct {
	Apps      string
	Scripts   string
	System    string
	Update    string
	Cleanup   string
	Service   string
	Info      string
	Exit      string
	Back      string
	Theme     string
	Cursor    string
	Check     string
	Dot       string
	Arrow     string
	Separator string
	Distro    string
	Kernel    string
	Shell     string
}

var NerdIcons = IconSet{
	Apps:      "", // nf-fa-download
	Scripts:   "", // nf-fa-code
	System:    "", // nf-fa-cog
	Update:    "", // nf-fa-refresh
	Cleanup:   "", // nf-fa-trash
	Service:   "", // nf-fa-server
	Info:      "", // nf-fa-info_circle
	Exit:      "", // nf-fa-sign_out
	Back:      "", // nf-fa-arrow_left
	Theme:     "", // nf-fa-palette
	Cursor:    "", // nf-fa-arrow_right (→)
	Check:     "", // nf-fa-check (✓)
	Dot:       "", // nf-fa-circle (•)
	Arrow:     "", // nf-fa-arrow_right (→)
	Separator: "", // nf-custom-folder_config (│)
	Distro:    "", // nf-linux-tux
	Kernel:    "", // nf-oct-cpu
	Shell:     "", // nf-fa-terminal
}

var ASCIIIcons = IconSet{
	Apps:      ">>",
	Scripts:   "<>",
	System:    "::",
	Update:    "^^",
	Cleanup:   "--",
	Service:   "[]",
	Info:      "(i)",
	Exit:      "=>",
	Back:      "<-",
	Theme:     "##",
	Cursor:    ">",
	Check:     "*",
	Dot:       ".",
	Arrow:     "->",
	Separator: "|",
	Distro:    "@",
	Kernel:    "#",
	Shell:     "$",
}

// Icons is the active icon set.
var Icons IconSet

const nerdFontFlagPath = ".config/mypctools/nerd-font"

// InitIcons reads the Nerd Font preference flag and sets Icons.
// Call once at startup.
func InitIcons() {
	iconsMu.Lock()
	defer iconsMu.Unlock()
	home, err := os.UserHomeDir()
	if err != nil {
		Icons = ASCIIIcons
		return
	}
	if _, err := os.Stat(home + "/" + nerdFontFlagPath); err == nil {
		Icons = NerdIcons
	} else {
		Icons = ASCIIIcons
	}
}

// UseNerdIcons reports whether Nerd Font icons are active.
func UseNerdIcons() bool {
	iconsMu.RLock()
	defer iconsMu.RUnlock()
	return Icons == NerdIcons
}

// GetIcons returns a copy of the current icon set (thread-safe).
func GetIcons() IconSet {
	iconsMu.RLock()
	defer iconsMu.RUnlock()
	return Icons
}

// ToggleIconSet flips between Nerd Font and ASCII icons and persists the choice.
func ToggleIconSet() {
	iconsMu.Lock()
	defer iconsMu.Unlock()
	home, err := os.UserHomeDir()
	if err != nil {
		return
	}
	flagPath := home + "/" + nerdFontFlagPath

	if Icons == NerdIcons {
		Icons = ASCIIIcons
		os.Remove(flagPath)
	} else {
		Icons = NerdIcons
		os.MkdirAll(home+"/.config/mypctools", 0755)
		os.WriteFile(flagPath, nil, 0644)
	}
}
