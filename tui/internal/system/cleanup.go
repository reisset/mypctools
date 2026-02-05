package system

import (
	"os"
	"os/exec"
	"path/filepath"

	"github.com/reisset/mypctools/tui/internal/cmd"
)

// CleanupCommand returns the package cleanup command for the given distro type.
func CleanupCommand(distroType cmd.DistroType) *exec.Cmd {
	switch distroType {
	case cmd.DistroDebian:
		return exec.Command("bash", "-c", "sudo apt autoremove -y && sudo apt autoclean && sudo apt clean")
	case cmd.DistroArch:
		// Remove orphans if any exist, then clear cache
		script := `
orphans=$(pacman -Qtdq 2>/dev/null)
if [ -n "$orphans" ]; then
    echo "$orphans" | sudo pacman -Rns --noconfirm -
fi
if command -v paccache >/dev/null 2>&1; then
    sudo paccache -rk2
else
    sudo pacman -Sc --noconfirm
fi
`
		return exec.Command("bash", "-c", script)
	case cmd.DistroFedora:
		return exec.Command("bash", "-c", "sudo dnf autoremove -y && sudo dnf clean all")
	default:
		return nil
	}
}

// ClearUserCaches removes user cache files (thumbnails, trash).
// Returns an error if any removal fails (other than path not existing).
func ClearUserCaches() error {
	home, err := os.UserHomeDir()
	if err != nil {
		return err
	}

	var errs []error

	// Clear thumbnails
	thumbnails := filepath.Join(home, ".cache", "thumbnails")
	if err := os.RemoveAll(thumbnails); err != nil {
		errs = append(errs, err)
	}

	// Clear trash
	trash := filepath.Join(home, ".local", "share", "Trash")
	if err := os.RemoveAll(trash); err != nil {
		errs = append(errs, err)
	}

	if len(errs) > 0 {
		return errs[0] // Return first error for simplicity
	}
	return nil
}
