package selfupdate

import (
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
)

const (
	releaseBaseURL = "https://github.com/reisset/mypctools/releases/latest/download"
)

// Update downloads the latest binary and pulls the latest scripts.
func Update(scriptsDir string) error {
	// Get current executable path
	exePath, err := os.Executable()
	if err != nil {
		return fmt.Errorf("failed to get executable path: %w", err)
	}
	exePath, err = filepath.EvalSymlinks(exePath)
	if err != nil {
		return fmt.Errorf("failed to resolve executable path: %w", err)
	}

	// Download and replace binary
	arch := runtime.GOARCH
	url := fmt.Sprintf("%s/mypctools-linux-%s", releaseBaseURL, arch)

	fmt.Printf("Downloading latest binary (%s)...\n", arch)
	if err := downloadAndReplace(url, exePath); err != nil {
		return fmt.Errorf("failed to update binary: %w", err)
	}
	fmt.Println("Binary updated.")

	// Git pull scripts
	fmt.Println("Pulling latest scripts...")
	if err := gitPull(scriptsDir); err != nil {
		return fmt.Errorf("failed to pull scripts: %w", err)
	}
	fmt.Println("Scripts updated.")

	return nil
}

// downloadAndReplace downloads a file and atomically replaces the destination.
func downloadAndReplace(url, destPath string) error {
	// Create temp file in same directory (for atomic rename)
	dir := filepath.Dir(destPath)
	tmpPath := filepath.Join(dir, ".mypctools.tmp")

	// Download to temp file
	resp, err := http.Get(url)
	if err != nil {
		return fmt.Errorf("download failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("download failed: HTTP %d", resp.StatusCode)
	}

	tmpFile, err := os.OpenFile(tmpPath, os.O_CREATE|os.O_WRONLY|os.O_TRUNC, 0755)
	if err != nil {
		return fmt.Errorf("failed to create temp file: %w", err)
	}

	_, err = io.Copy(tmpFile, resp.Body)
	tmpFile.Close()
	if err != nil {
		os.Remove(tmpPath)
		return fmt.Errorf("failed to write temp file: %w", err)
	}

	// Atomic replace
	if err := os.Rename(tmpPath, destPath); err != nil {
		os.Remove(tmpPath)
		return fmt.Errorf("failed to replace binary: %w", err)
	}

	return nil
}

// gitPull runs git pull in the specified directory.
func gitPull(dir string) error {
	cmd := exec.Command("git", "pull", "--ff-only")
	cmd.Dir = dir
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}
