package system

import (
	"os/exec"
)

// Notify sends a desktop notification via notify-send.
// Silently fails if notify-send is unavailable.
func Notify(title, body string) {
	exec.Command("notify-send", title, body).Run()
}
