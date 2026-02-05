package pkg

import (
	"testing"

	"github.com/reisset/mypctools/tui/internal/cmd"
)

func TestCommandExists(t *testing.T) {
	// "ls" should exist on any Linux system
	if !commandExists("ls") {
		t.Error("expected 'ls' to exist")
	}

	// Non-existent command
	if commandExists("this-command-definitely-does-not-exist-12345") {
		t.Error("expected non-existent command to return false")
	}
}

func TestIsAppInstalled_CommandCheck(t *testing.T) {
	// "ls" exists, so an app with CommandCheck="ls" should be detected as installed
	app := &App{
		Name:         "Test",
		CommandCheck: "ls",
	}
	if !IsAppInstalled(app, cmd.DistroArch) {
		t.Error("expected app with CommandCheck='ls' to be detected as installed")
	}
}

func TestIsAppInstalled_NoMethods(t *testing.T) {
	app := &App{
		Name: "Ghost",
		// No command check, no packages, no flatpak
	}
	if IsAppInstalled(app, cmd.DistroArch) {
		t.Error("expected app with no detection methods to return false")
	}
}

func TestHasFlatpak(t *testing.T) {
	// Just ensure it doesn't panic — result depends on system
	_ = HasFlatpak()
}

func TestRefreshFlatpakCache(t *testing.T) {
	// Ensure it doesn't panic
	RefreshFlatpakCache()
}

func TestIsAppInstalled_CommandCheckPriority(t *testing.T) {
	// If CommandCheck succeeds, native package check shouldn't matter
	app := &App{
		Name:         "Bash",
		CommandCheck: "bash",
		PacmanPkg:    "nonexistent-package-xyz",
	}
	if !IsAppInstalled(app, cmd.DistroArch) {
		t.Error("command check should take priority over native package check")
	}
}
