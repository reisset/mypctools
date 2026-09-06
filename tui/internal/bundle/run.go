package bundle

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

// Find returns the bundle with the given ID.
func Find(id string) (Bundle, bool) {
	for _, b := range All() {
		if b.ID == id {
			return b, true
		}
	}
	return Bundle{}, false
}

// ScriptPath returns rootDir/scripts/<id>/<action>.sh. The ID and action are
// validated because they are interpolated into a path that gets executed.
func ScriptPath(rootDir, id, action string) (string, error) {
	if strings.ContainsAny(id, `/\`) {
		return "", fmt.Errorf("invalid bundle ID: %s", id)
	}
	if action != "install" && action != "uninstall" {
		return "", fmt.Errorf("invalid action: %s", action)
	}
	path := filepath.Join(rootDir, "scripts", id, action+".sh")
	if _, err := os.Stat(path); err != nil {
		return "", fmt.Errorf("script not found at %s — run 'mypctools update'", path)
	}
	return path, nil
}

// Run executes a bundle script attached to the current terminal, so sudo can
// prompt and output is visible as it happens. Scripts are told not to prompt;
// see is_noninteractive in lib/print.sh.
func Run(rootDir string, b Bundle, action string) error {
	path, err := ScriptPath(rootDir, b.ID, action)
	if err != nil {
		return err
	}
	c := exec.Command("bash", path)
	c.Stdin = os.Stdin
	c.Stdout = os.Stdout
	c.Stderr = os.Stderr
	c.Env = append(os.Environ(), "MYPCTOOLS_NONINTERACTIVE=1")
	return c.Run()
}
