package state

import (
	"context"
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
		// Separate contexts — fetch gets 5s, rev-list gets 2s.
		fetchCtx, fetchCancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer fetchCancel()

		cmd := exec.CommandContext(fetchCtx, "git", "-C", rootDir, "fetch", "origin", "main")
		if err := cmd.Run(); err != nil {
			return UpdateCountMsg{Count: 0}
		}

		revCtx, revCancel := context.WithTimeout(context.Background(), 2*time.Second)
		defer revCancel()

		out, err := exec.CommandContext(revCtx, "git", "-C", rootDir, "rev-list", "HEAD..origin/main", "--count").Output()
		if err != nil {
			return UpdateCountMsg{Count: 0}
		}

		count, _ := strconv.Atoi(strings.TrimSpace(string(out)))
		return UpdateCountMsg{Count: count}
	}
}
