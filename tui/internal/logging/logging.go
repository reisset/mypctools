package logging

import (
	"fmt"
	"os"
	"path/filepath"
	"sync"
	"time"
)

var (
	logMu      sync.Mutex
	logDirPath string
)

// ensureLogDir is only ever called with logMu held, so it needs no locking of
// its own. A failed lookup leaves the path empty so the next call retries.
func ensureLogDir() string {
	if logDirPath != "" {
		return logDirPath
	}
	home, err := os.UserHomeDir()
	if err != nil {
		return ""
	}
	logDirPath = filepath.Join(home, ".local", "share", "mypctools")
	os.MkdirAll(logDirPath, 0755)
	return logDirPath
}

// LogAction appends a timestamped line to ~/.local/share/mypctools/mypctools.log.
func LogAction(action string) error {
	logMu.Lock()
	defer logMu.Unlock()

	dir := ensureLogDir()
	if dir == "" {
		return fmt.Errorf("failed to determine log directory")
	}

	logFile := filepath.Join(dir, "mypctools.log")
	f, err := os.OpenFile(logFile, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0600)
	if err != nil {
		return err
	}
	defer f.Close()

	timestamp := time.Now().Format("2006-01-02 15:04:05")
	_, err = fmt.Fprintf(f, "%s | %s\n", timestamp, action)
	return err
}
