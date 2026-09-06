package bundle

import (
	"os"
	"os/exec"
)

// SyncInstalled re-runs install.sh for every installed AutoSync bundle.
// Returns the names of bundles that were successfully synced.
func SyncInstalled(rootDir string) []string {
	var synced []string
	for _, b := range All() {
		if !b.AutoSync || !IsInstalled(&b) {
			continue
		}
		script, err := ScriptPath(rootDir, b.ID, "install")
		if err != nil {
			continue
		}
		cmd := exec.Command("bash", script)
		// Stdin is nil here, so scripts are already headless; say so explicitly
		// rather than relying on that being noticed.
		cmd.Env = append(os.Environ(), "MYPCTOOLS_NONINTERACTIVE=1")
		if err := cmd.Run(); err == nil {
			synced = append(synced, b.Name)
		}
	}
	return synced
}
