package pkg

import (
	"os/exec"
	"strings"
	"sync"
	"time"

	"github.com/reisset/mypctools/tui/internal/cmd"
)

// Flatpak cache to avoid running `flatpak list` for every app check.
var (
	flatpakCache     map[string]bool
	flatpakCacheTime time.Time
	flatpakCacheMu   sync.Mutex
	flatpakCacheTTL  = 30 * time.Second
)

// IsAppInstalled checks if an app is installed via command, package manager, or flatpak.
func IsAppInstalled(app *App, distroType cmd.DistroType) bool {
	// 1. Check command existence first (fastest)
	if app.CommandCheck != "" && commandExists(app.CommandCheck) {
		return true
	}

	// 2. Check native package manager
	if isNativePkgInstalled(app, distroType) {
		return true
	}

	// 3. Check flatpak
	if app.FlatpakID != "" && isFlatpakInstalled(app.FlatpakID) {
		return true
	}

	return false
}

// commandExists checks if a command is available in PATH.
func commandExists(name string) bool {
	_, err := exec.LookPath(name)
	return err == nil
}

// isNativePkgInstalled checks if a package is installed via the native package manager.
func isNativePkgInstalled(app *App, distroType cmd.DistroType) bool {
	switch distroType {
	case cmd.DistroArch:
		if app.PacmanPkg == "" {
			return false
		}
		// pacman -Q returns 0 if package is installed
		cmd := exec.Command("pacman", "-Q", app.PacmanPkg)
		return cmd.Run() == nil

	case cmd.DistroDebian:
		if app.AptPkg == "" {
			return false
		}
		// dpkg -s returns 0 if package is installed
		cmd := exec.Command("dpkg", "-s", app.AptPkg)
		return cmd.Run() == nil

	case cmd.DistroFedora:
		// Fedora names sometimes match Debian, sometimes Arch - try both
		if app.AptPkg != "" {
			cmd := exec.Command("rpm", "-q", app.AptPkg)
			if cmd.Run() == nil {
				return true
			}
		}
		if app.PacmanPkg != "" && app.PacmanPkg != app.AptPkg {
			cmd := exec.Command("rpm", "-q", app.PacmanPkg)
			if cmd.Run() == nil {
				return true
			}
		}
		return false
	}

	return false
}

// ensureFlatpakCache populates the flatpak cache if it's empty or expired.
func ensureFlatpakCache() {
	flatpakCacheMu.Lock()
	defer flatpakCacheMu.Unlock()

	// Check if cache is still valid
	if flatpakCache != nil && time.Since(flatpakCacheTime) < flatpakCacheTTL {
		return
	}

	// Rebuild cache
	flatpakCache = make(map[string]bool)
	flatpakCacheTime = time.Now()

	if !commandExists("flatpak") {
		return
	}

	out, err := exec.Command("flatpak", "list", "--app", "--columns=application").Output()
	if err != nil {
		return
	}

	lines := strings.Split(string(out), "\n")
	for _, line := range lines {
		id := strings.TrimSpace(line)
		if id != "" {
			flatpakCache[id] = true
		}
	}
}

// RefreshFlatpakCache invalidates the flatpak cache, forcing a refresh on next check.
// Call this after installing or uninstalling flatpak apps.
func RefreshFlatpakCache() {
	flatpakCacheMu.Lock()
	defer flatpakCacheMu.Unlock()
	flatpakCache = nil
}

// isFlatpakInstalled checks if a flatpak app is installed using the cache.
func isFlatpakInstalled(flatpakID string) bool {
	if !commandExists("flatpak") {
		return false
	}

	ensureFlatpakCache()

	flatpakCacheMu.Lock()
	defer flatpakCacheMu.Unlock()
	return flatpakCache[flatpakID]
}

// HasFlatpak checks if flatpak is available on the system.
func HasFlatpak() bool {
	return commandExists("flatpak")
}
