package selfupdate

import (
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
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
	binaryName := fmt.Sprintf("mypctools-linux-%s", arch)
	binaryURL := fmt.Sprintf("%s/%s", releaseBaseURL, binaryName)
	checksumsURL := fmt.Sprintf("%s/checksums.txt", releaseBaseURL)

	fmt.Printf("Downloading latest binary (%s)...\n", arch)
	if err := downloadAndReplace(binaryURL, checksumsURL, binaryName, exePath); err != nil {
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

// downloadAndReplace downloads a file, verifies its checksum, and atomically replaces the destination.
func downloadAndReplace(binaryURL, checksumsURL, binaryName, destPath string) error {
	// Create temp file in same directory (for atomic rename)
	dir := filepath.Dir(destPath)
	tmpFile, err := os.CreateTemp(dir, ".mypctools-update-*")
	if err != nil {
		return fmt.Errorf("failed to create temp file: %w", err)
	}
	tmpPath := tmpFile.Name()
	defer os.Remove(tmpPath) // Clean up on any error path

	// Download binary to temp file
	resp, err := http.Get(binaryURL)
	if err != nil {
		tmpFile.Close()
		return fmt.Errorf("download failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		tmpFile.Close()
		return fmt.Errorf("download failed: HTTP %d", resp.StatusCode)
	}

	// Write and compute SHA256 simultaneously
	hasher := sha256.New()
	writer := io.MultiWriter(tmpFile, hasher)

	_, err = io.Copy(writer, resp.Body)
	tmpFile.Close()
	if err != nil {
		return fmt.Errorf("failed to write temp file: %w", err)
	}

	actualHash := hex.EncodeToString(hasher.Sum(nil))

	// Verify checksum if checksums.txt is available
	expectedHash, err := fetchExpectedChecksum(checksumsURL, binaryName)
	if err != nil {
		fmt.Printf("Warning: checksum verification skipped (%v)\n", err)
	} else if actualHash != expectedHash {
		return fmt.Errorf("checksum mismatch: expected %s, got %s", expectedHash, actualHash)
	} else {
		fmt.Println("Checksum verified.")
	}

	// Set executable permission
	if err := os.Chmod(tmpPath, 0755); err != nil {
		return fmt.Errorf("failed to set permissions: %w", err)
	}

	// Atomic replace
	if err := os.Rename(tmpPath, destPath); err != nil {
		return fmt.Errorf("failed to replace binary: %w", err)
	}

	return nil
}

// fetchExpectedChecksum downloads checksums.txt and extracts the hash for the given filename.
func fetchExpectedChecksum(checksumsURL, filename string) (string, error) {
	resp, err := http.Get(checksumsURL)
	if err != nil {
		return "", fmt.Errorf("failed to download checksums: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("checksums not available: HTTP %d", resp.StatusCode)
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", fmt.Errorf("failed to read checksums: %w", err)
	}

	// Parse checksums.txt format: "<hash>  <filename>" or "<hash> <filename>"
	for _, line := range strings.Split(string(body), "\n") {
		fields := strings.Fields(line)
		if len(fields) == 2 && fields[1] == filename {
			return fields[0], nil
		}
	}

	return "", fmt.Errorf("checksum not found for %s", filename)
}

// gitPull runs git pull in the specified directory.
func gitPull(dir string) error {
	cmd := exec.Command("git", "pull", "--ff-only")
	cmd.Dir = dir
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}
