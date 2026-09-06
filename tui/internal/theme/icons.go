package theme

import (
	"os"
	"path/filepath"
	"strings"
	"sync"
)

var iconsMu sync.RWMutex

// Icon pairs: nerd font glyph + ASCII fallback.
type IconSet struct {
	Check  string
	Dot    string
	Distro string
	Kernel string
	Shell  string
}

var NerdIcons = IconSet{
	Check:  "", // nf-fa-check
	Dot:    "", // nf-fa-circle
	Distro: "", // nf-linux-tux
	Kernel: "", // nf-oct-cpu
	Shell:  "", // nf-fa-terminal
}

var ASCIIIcons = IconSet{
	Check:  "*",
	Dot:    ".",
	Distro: "@",
	Kernel: "#",
	Shell:  "$",
}

// Icons is the active icon set.
var Icons IconSet

// fontDirs are searched for a Nerd Font. Covers both install paths in
// lib/terminal-install.sh: the distro package and the extracted GitHub zip.
var fontDirs = []string{
	"/usr/share/fonts",
	".local/share/fonts", // relative to $HOME
}

// InitIcons picks the icon set by detecting an installed Nerd Font.
// MYPCTOOLS_ICONS=nerd|ascii overrides detection. Call once at startup.
func InitIcons() {
	iconsMu.Lock()
	defer iconsMu.Unlock()

	switch os.Getenv("MYPCTOOLS_ICONS") {
	case "nerd":
		Icons = NerdIcons
		return
	case "ascii":
		Icons = ASCIIIcons
		return
	}

	if hasNerdFont() {
		Icons = NerdIcons
	} else {
		Icons = ASCIIIcons
	}
}

// hasNerdFont reports whether any font file looks like a Nerd Font. It walks a
// couple of levels of the font directories rather than shelling out to
// fc-list, which was dropped in v0.39.0 for being slow.
func hasNerdFont() bool {
	home, _ := os.UserHomeDir()

	for _, dir := range fontDirs {
		if !filepath.IsAbs(dir) {
			if home == "" {
				continue
			}
			dir = filepath.Join(home, dir)
		}
		if nerdFontIn(dir, 2) {
			return true
		}
	}
	return false
}

func nerdFontIn(dir string, depth int) bool {
	entries, err := os.ReadDir(dir)
	if err != nil {
		return false
	}
	for _, e := range entries {
		if e.IsDir() {
			if depth > 0 && nerdFontIn(filepath.Join(dir, e.Name()), depth-1) {
				return true
			}
			continue
		}
		if strings.Contains(strings.ToLower(e.Name()), "nerd") {
			return true
		}
	}
	return false
}

// GetIcons returns a copy of the current icon set (thread-safe).
func GetIcons() IconSet {
	iconsMu.RLock()
	defer iconsMu.RUnlock()
	return Icons
}
