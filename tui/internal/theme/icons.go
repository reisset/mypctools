package theme

import (
	"os/exec"
	"strings"
)

// Icon pairs: nerd font glyph + ASCII fallback.
type IconSet struct {
	Apps    string
	Scripts string
	System  string
	AI      string
	Browser string
	Gaming  string
	Media   string
	Dev     string
	Update  string
	Cleanup string
	Service string
	Info    string
	Exit    string
	Back    string
	Theme   string
}

var NerdIcons = IconSet{
	Apps:    "\uf019",  // nf-fa-download
	Scripts: "\uf121",  // nf-fa-code
	System:  "\uf013",  // nf-fa-cog
	AI:      "\uf0eb",  // nf-fa-lightbulb_o
	Browser: "\uf0ac",  // nf-fa-globe
	Gaming:  "\uf11b",  // nf-fa-gamepad
	Media:   "\uf001",  // nf-fa-music
	Dev:     "\uf120",  // nf-fa-terminal
	Update:  "\uf021",  // nf-fa-refresh
	Cleanup: "\uf1b8",  // nf-fa-trash
	Service: "\uf233",  // nf-fa-server
	Info:    "\uf05a",  // nf-fa-info_circle
	Exit:    "\uf2f5",  // nf-fa-sign_out
	Back:    "\uf060",  // nf-fa-arrow_left
	Theme:   "\uf53f",  // nf-fa-palette
}

var ASCIIIcons = IconSet{
	Apps:    ">>",
	Scripts: "<>",
	System:  "::",
	AI:      "**",
	Browser: "@@",
	Gaming:  "><",
	Media:   "~>",
	Dev:     "$>",
	Update:  "^^",
	Cleanup: "--",
	Service: "[]",
	Info:    "(i)",
	Exit:    "=>",
	Back:    "<-",
	Theme:   "##",
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
