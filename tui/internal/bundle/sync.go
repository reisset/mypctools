package bundle

import (
	"os"
	"os/exec"
	"path/filepath"
)

// SyncInstalled re-runs install.sh for every installed AutoSync bundle.
// Returns the names of bundles that were successfully synced.
func SyncInstalled(rootDir string) []string {
	var synced []string
	for _, b := range All() {
		if !b.AutoSync || !IsInstalled(&b) {
			continue
		}
		script := filepath.Join(rootDir, "scripts", b.ID, "install.sh")
		cmd := exec.Command("bash", script)
		cmd.Env = os.Environ()
		if err := cmd.Run(); err == nil {
			synced = append(synced, b.Name)
		}
	}
	return synced
}
