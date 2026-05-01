package theme

import (
	"os/exec"
	"strings"
)

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

// Icons is the active icon set, chosen at init.
var Icons IconSet

func init() {
	if hasNerdFont() {
		Icons = NerdIcons
	} else {
		Icons = ASCIIIcons
	}
}

func hasNerdFont() bool {
	out, err := exec.Command("fc-list", ":", "family").Output()
	if err != nil {
		return false
	}
	return strings.Contains(strings.ToLower(string(out)), "nerd")
}
