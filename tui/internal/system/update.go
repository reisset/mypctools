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
		return exec.Command("sudo", "pacman", "-Syu", "--noconfirm")
	case cmd.DistroFedora:
		return exec.Command("sudo", "dnf", "upgrade", "-y")
	default:
		return nil
	}
}
