package system

import (
	"os/exec"

	"github.com/reisset/mypctools/tui/internal/cmd"
)

// UpdateCommand returns the system update command for the given distro type.
func UpdateCommand(distroType cmd.DistroType) *exec.Cmd {
	switch distroType {
	case cmd.DistroDebian:
		return exec.Command("bash", "-c", "sudo apt update && sudo apt upgrade -y")
	case cmd.DistroArch:
		// paru also covers AUR packages, which bundles like gnome-ubuntu install.
		// Deliberately no --noconfirm: a full upgrade can prompt to replace or
		// remove packages, and auto-answering those is how an Arch box breaks.
		if _, err := exec.LookPath("paru"); err == nil {
			return exec.Command("paru", "-Syu")
		}
		return exec.Command("sudo", "pacman", "-Syu")
	default:
		return nil
	}
}
