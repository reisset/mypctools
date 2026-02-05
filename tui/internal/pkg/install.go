package pkg

import (
	"fmt"
	"os/exec"

	"github.com/reisset/mypctools/tui/internal/cmd"
)

// InstallCommand returns the command to install an app for the given distro.
// It tries native PM first, then flatpak, then fallback.
// Returns the command string and a description of the method used.
func InstallCommand(app *App, distroType cmd.DistroType) (string, string) {
	// Try native package manager first
	switch distroType {
	case cmd.DistroArch:
		if app.PacmanPkg != "" {
			return fmt.Sprintf("sudo pacman -S --noconfirm --needed %s", app.PacmanPkg), "pacman"
		}
	case cmd.DistroDebian:
		if app.AptPkg != "" {
			return fmt.Sprintf("sudo apt install -y %s", app.AptPkg), "apt"
		}
	case cmd.DistroFedora:
		if app.AptPkg != "" {
			return fmt.Sprintf("sudo dnf install -y %s", app.AptPkg), "dnf"
		}
		if app.PacmanPkg != "" {
			return fmt.Sprintf("sudo dnf install -y %s", app.PacmanPkg), "dnf"
		}
	}

	// Flatpak fallback
	if app.FlatpakID != "" && HasFlatpak() {
		return fmt.Sprintf("flatpak install -y flathub %s", app.FlatpakID), "flatpak"
	}

	// Custom fallback
	if app.FallbackCmd != "" {
		return app.FallbackCmd, "fallback"
	}

	return "", ""
}

// BuildInstallCmd creates an exec.Cmd for installing an app.
// Returns nil if no installation method is available.
func BuildInstallCmd(app *App, distroType cmd.DistroType) *exec.Cmd {
	cmdStr, _ := InstallCommand(app, distroType)
	if cmdStr == "" {
		return nil
	}

	return exec.Command("bash", "-c", cmdStr)
}

// InstallMethodDescription returns a human-readable description of the install method.
func InstallMethodDescription(app *App, distroType cmd.DistroType) string {
	_, method := InstallCommand(app, distroType)
	switch method {
	case "pacman":
		return "via pacman"
	case "apt":
		return "via apt"
	case "dnf":
		return "via dnf"
	case "flatpak":
		return "via Flatpak"
	case "fallback":
		return "via custom installer"
	default:
		return "no method available"
	}
}

// CanInstall returns true if there's at least one installation method available.
func CanInstall(app *App, distroType cmd.DistroType) bool {
	cmdStr, _ := InstallCommand(app, distroType)
	return cmdStr != ""
}
