package logging

import (
	"fmt"
	"os"
	"path/filepath"
	"time"
)

// LogAction appends a timestamped line to ~/.local/share/mypctools/mypctools.log.
func LogAction(action string) error {
	home, err := os.UserHomeDir()
	if err != nil {
		return err
	}

	logDir := filepath.Join(home, ".local", "share", "mypctools")
	if err := os.MkdirAll(logDir, 0755); err != nil {
		return err
	}

	logFile := filepath.Join(logDir, "mypctools.log")
	f, err := os.OpenFile(logFile, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		return err
	}
	defer f.Close()

	timestamp := time.Now().Format("2006-01-02 15:04:05")
	_, err = fmt.Fprintf(f, "%s | %s\n", timestamp, action)
	return err
}
