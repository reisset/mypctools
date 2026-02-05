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
		ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
		defer cancel()

		cmd := exec.CommandContext(ctx, "git", "-C", rootDir, "fetch", "origin", "main")
		if err := cmd.Run(); err != nil {
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
