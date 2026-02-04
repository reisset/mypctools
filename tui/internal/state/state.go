package state

import "github.com/reisset/mypctools/tui/internal/cmd"

// Shared holds global state accessible by all screens.
type Shared struct {
	Distro        cmd.DistroInfo
	RootDir       string // Absolute path to mypctools repo root
	UpdateCount   int    // Commits behind origin/main (0 = up to date)
	TerminalWidth int
	TerminalHeight int
}
