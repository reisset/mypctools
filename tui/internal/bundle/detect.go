package bundle

import (
	"os"
	"path/filepath"
)

// IsInstalled checks if a bundle is installed by testing its marker path.
func IsInstalled(b *Bundle) bool {
	home, err := os.UserHomeDir()
	if err != nil {
		return false
	}
	markerPath := filepath.Join(home, b.MarkerPath)
	_, err = os.Stat(markerPath)
	return err == nil
}
