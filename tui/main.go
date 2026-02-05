package main

import (
	"fmt"
	"os"
	"path/filepath"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/reisset/mypctools/tui/internal/app"
	"github.com/reisset/mypctools/tui/internal/cmd"
	"github.com/reisset/mypctools/tui/internal/config"
	"github.com/reisset/mypctools/tui/internal/screen/mainmenu"
	"github.com/reisset/mypctools/tui/internal/selfupdate"
	"github.com/reisset/mypctools/tui/internal/state"
	"github.com/reisset/mypctools/tui/internal/theme"
)

func main() {
	// CLI flags
	if len(os.Args) > 1 {
		switch os.Args[1] {
		case "--help", "-h":
			fmt.Printf("mypctools v%s\n", config.Version)
			fmt.Println("A personal TUI for managing scripts and apps")
			fmt.Println("Built with Bubble Tea by Charm")
			fmt.Println()
			fmt.Println("Usage: mypctools [command] [option]")
			fmt.Println()
			fmt.Println("Commands:")
			fmt.Println("  update           Update binary and scripts to latest version")
			fmt.Println()
			fmt.Println("Options:")
			fmt.Println("  --help, -h       Show this help message")
			fmt.Println("  --version, -v    Show version number")
			os.Exit(0)
		case "--version", "-v":
			fmt.Printf("mypctools v%s\n", config.Version)
			os.Exit(0)
		case "update":
			scriptsDir := findRootDir()
			fmt.Println("Updating mypctools...")
			if err := selfupdate.Update(scriptsDir); err != nil {
				fmt.Fprintf(os.Stderr, "Update failed: %v\n", err)
				os.Exit(1)
			}
			fmt.Println("\nUpdate complete! Run 'mypctools' to start.")
			os.Exit(0)
		default:
			fmt.Fprintf(os.Stderr, "Unknown option: %s\nRun 'mypctools --help' for usage.\n", os.Args[1])
			os.Exit(1)
		}
	}

	// Don't run as root
	if os.Geteuid() == 0 {
		fmt.Fprintln(os.Stderr, "Do not run as root. Use your normal user.")
		os.Exit(1)
	}

	// Find the mypctools root directory (parent of tui/)
	rootDir := findRootDir()

	// Load theme
	theme.Load()

	// Detect distro
	distro := cmd.DetectDistro()

	// Build shared state
	shared := &state.Shared{
		Distro:  distro,
		RootDir: rootDir,
	}

	// Create initial screen
	menu := mainmenu.New(shared)

	// Create and run the program
	p := tea.NewProgram(
		app.NewModel(menu, shared),
		tea.WithAltScreen(),
	)

	// Start background update check
	go func() {
		defer func() {
			if r := recover(); r != nil {
				// Silently ignore panics in background goroutine
				// (program may have exited before Send completes)
			}
		}()
		result := state.CheckForUpdates(rootDir)()
		p.Send(result)
	}()

	if _, err := p.Run(); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
}

// findRootDir locates the mypctools repo root.
// It walks up from the executable path looking for scripts/ directory.
func findRootDir() string {
	// Try ~/.local/share/mypctools first (standard install location)
	homeShare := filepath.Join(os.Getenv("HOME"), ".local", "share", "mypctools")
	if _, err := os.Stat(filepath.Join(homeShare, "scripts")); err == nil {
		return homeShare
	}

	// Try relative to executable
	exe, err := os.Executable()
	if err == nil {
		exe, _ = filepath.EvalSymlinks(exe)
		dir := filepath.Dir(exe)
		// If we're in tui/, go up one level
		if filepath.Base(dir) == "tui" {
			dir = filepath.Dir(dir)
		}
		if _, err := os.Stat(filepath.Join(dir, "scripts")); err == nil {
			return dir
		}
	}

	// Try CWD
	cwd, err := os.Getwd()
	if err == nil {
		if _, err := os.Stat(filepath.Join(cwd, "scripts")); err == nil {
			return cwd
		}
		// Try parent of CWD (if running from tui/)
		parent := filepath.Dir(cwd)
		if _, err := os.Stat(filepath.Join(parent, "scripts")); err == nil {
			return parent
		}
	}

	// Fallback: ~/.local/share/mypctools
	return homeShare
}
