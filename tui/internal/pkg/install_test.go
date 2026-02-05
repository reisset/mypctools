package pkg

import (
	"strings"
	"testing"

	"github.com/reisset/mypctools/tui/internal/cmd"
)

func TestInstallCommand_Arch(t *testing.T) {
	app := &App{
		Name:      "Firefox",
		PacmanPkg: "firefox",
		AptPkg:    "firefox",
		DnfPkg:    "firefox",
		FlatpakID: "org.mozilla.firefox",
	}

	cmdStr, method := InstallCommand(app, cmd.DistroArch)
	if method != "pacman" {
		t.Errorf("expected method 'pacman', got %q", method)
	}
	if !strings.Contains(cmdStr, "pacman -S") {
		t.Errorf("expected pacman command, got %q", cmdStr)
	}
	if !strings.Contains(cmdStr, "firefox") {
		t.Errorf("expected package name 'firefox' in command, got %q", cmdStr)
	}
}

func TestInstallCommand_Debian(t *testing.T) {
	app := &App{
		Name:   "VLC",
		AptPkg: "vlc",
	}

	cmdStr, method := InstallCommand(app, cmd.DistroDebian)
	if method != "apt" {
		t.Errorf("expected method 'apt', got %q", method)
	}
	if !strings.Contains(cmdStr, "apt install") {
		t.Errorf("expected apt command, got %q", cmdStr)
	}
}

func TestInstallCommand_Fedora_WithDnfPkg(t *testing.T) {
	app := &App{
		Name:   "Firefox",
		AptPkg: "firefox",
		DnfPkg: "firefox",
	}

	cmdStr, method := InstallCommand(app, cmd.DistroFedora)
	if method != "dnf" {
		t.Errorf("expected method 'dnf', got %q", method)
	}
	if !strings.Contains(cmdStr, "dnf install") {
		t.Errorf("expected dnf command, got %q", cmdStr)
	}
}

func TestInstallCommand_Fedora_NoDnfPkg_NoFallbackToApt(t *testing.T) {
	app := &App{
		Name:   "Docker",
		AptPkg: "docker.io", // Debian-specific name
		// DnfPkg intentionally empty
	}

	cmdStr, method := InstallCommand(app, cmd.DistroFedora)
	// Should NOT fall back to using AptPkg with dnf
	if method == "dnf" {
		t.Errorf("should not use apt package name '%s' with dnf, got command %q", app.AptPkg, cmdStr)
	}
}

func TestInstallCommand_FlatpakFallback(t *testing.T) {
	app := &App{
		Name:      "ProtonUp-Qt",
		FlatpakID: "net.davidotek.pupgui2",
	}

	// On Arch with no pacman pkg, should try flatpak
	cmdStr, method := InstallCommand(app, cmd.DistroArch)
	if HasFlatpak() {
		if method != "flatpak" {
			t.Errorf("expected method 'flatpak', got %q", method)
		}
		if !strings.Contains(cmdStr, "flatpak install") {
			t.Errorf("expected flatpak command, got %q", cmdStr)
		}
	}
	// If flatpak not installed, both should be empty (no fallback cmd)
	if !HasFlatpak() {
		if cmdStr != "" || method != "" {
			t.Errorf("expected empty command without flatpak, got cmd=%q method=%q", cmdStr, method)
		}
	}
}

func TestInstallCommand_CustomFallback(t *testing.T) {
	app := &App{
		Name:        "Ollama",
		FallbackCmd: "curl -fsSL https://ollama.com/install.sh | sh",
	}

	cmdStr, method := InstallCommand(app, cmd.DistroDebian)
	if method != "fallback" {
		t.Errorf("expected method 'fallback', got %q", method)
	}
	if cmdStr != app.FallbackCmd {
		t.Errorf("expected fallback command, got %q", cmdStr)
	}
}

func TestInstallCommand_NoMethod(t *testing.T) {
	app := &App{
		Name: "SomeApp",
		// No package names, no flatpak, no fallback
	}

	cmdStr, method := InstallCommand(app, cmd.DistroArch)
	if cmdStr != "" || method != "" {
		t.Errorf("expected empty results for app with no install method, got cmd=%q method=%q", cmdStr, method)
	}
}

func TestCanInstall(t *testing.T) {
	appWithPkg := &App{PacmanPkg: "firefox"}
	appWithout := &App{Name: "nothing"}

	if !CanInstall(appWithPkg, cmd.DistroArch) {
		t.Error("expected CanInstall=true for app with pacman pkg on Arch")
	}
	if CanInstall(appWithout, cmd.DistroArch) {
		t.Error("expected CanInstall=false for app with no install method")
	}
}

func TestInstallMethodDescription(t *testing.T) {
	tests := []struct {
		name     string
		app      *App
		distro   cmd.DistroType
		expected string
	}{
		{"pacman", &App{PacmanPkg: "firefox"}, cmd.DistroArch, "pacman"},
		{"apt", &App{AptPkg: "firefox"}, cmd.DistroDebian, "apt"},
		{"dnf", &App{DnfPkg: "firefox"}, cmd.DistroFedora, "dnf"},
		{"fallback", &App{FallbackCmd: "curl ..."}, cmd.DistroArch, "custom installer"},
		{"none", &App{}, cmd.DistroArch, ""},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := InstallMethodDescription(tt.app, tt.distro)
			if got != tt.expected {
				t.Errorf("expected %q, got %q", tt.expected, got)
			}
		})
	}
}

func TestBuildInstallCmd_Nil(t *testing.T) {
	a := &App{Name: "nothing"}
	c := BuildInstallCmd(a, cmd.DistroArch)
	if c != nil {
		t.Error("expected nil cmd for app with no install method")
	}
}

func TestBuildInstallCmd_NotNil(t *testing.T) {
	a := &App{PacmanPkg: "firefox"}
	c := BuildInstallCmd(a, cmd.DistroArch)
	if c == nil {
		t.Error("expected non-nil cmd for app with pacman pkg on Arch")
	}
}
