package state

import (
	"os/exec"
	"strconv"
	"strings"
	"time"

	tea "github.com/charmbracelet/bubbletea"
)

// UpdateCountMsg carries the number of commits behind origin/main.
type UpdateCountMsg struct {
	Count int
}

// CheckForUpdates runs git fetch + rev-list in the background.
func CheckForUpdates(rootDir string) tea.Cmd {
	return func() tea.Msg {
		ctx := exec.Command("git", "-C", rootDir, "fetch", "origin", "main")
		ctx.Env = append(ctx.Environ())

		done := make(chan error, 1)
		go func() { done <- ctx.Run() }()

		select {
		case err := <-done:
			if err != nil {
				return UpdateCountMsg{Count: 0}
			}
		case <-time.After(3 * time.Second):
			return UpdateCountMsg{Count: 0}
		}

		out, err := exec.Command("git", "-C", rootDir, "rev-list", "HEAD..origin/main", "--count").Output()
		if err != nil {
			return UpdateCountMsg{Count: 0}
		}

		count, _ := strconv.Atoi(strings.TrimSpace(string(out)))
		return UpdateCountMsg{Count: count}
	}
}
