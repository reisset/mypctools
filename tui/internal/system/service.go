package system

import (
	"os/exec"
	"strings"
)

// KnownServices is the list of common services to display.
var KnownServices = []string{
	"docker",
	"ssh",
	"sshd",
	"bluetooth",
	"cups",
	"NetworkManager",
	"avahi-daemon",
	"cron",
	"crond",
	"ufw",
	"firewalld",
}

// ServiceStatus holds the status of a systemd service.
type ServiceStatus struct {
	Name    string
	Active  string // "active", "inactive", "failed", "unknown"
	Enabled string // "enabled", "disabled", "static", "unknown"
}

// GetServiceStatus returns the status of a single service.
func GetServiceStatus(name string) ServiceStatus {
	status := ServiceStatus{Name: name, Active: "unknown", Enabled: "unknown"}

	// Check if service exists
	if err := exec.Command("systemctl", "list-unit-files", name+".service").Run(); err != nil {
		return status
	}

	// Get active status
	if out, err := exec.Command("systemctl", "is-active", name).Output(); err == nil {
		status.Active = strings.TrimSpace(string(out))
	} else {
		// is-active returns exit code 3 for inactive, still has output
		if exitErr, ok := err.(*exec.ExitError); ok {
			if exitErr.ExitCode() == 3 {
				status.Active = "inactive"
			}
		}
	}

	// Get enabled status
	if out, err := exec.Command("systemctl", "is-enabled", name).Output(); err == nil {
		status.Enabled = strings.TrimSpace(string(out))
	} else {
		// is-enabled returns exit code 1 for disabled
		if exitErr, ok := err.(*exec.ExitError); ok {
			if exitErr.ExitCode() == 1 {
				status.Enabled = "disabled"
			}
		}
	}

	return status
}

// ServiceExists checks if a service unit file exists.
func ServiceExists(name string) bool {
	err := exec.Command("systemctl", "list-unit-files", name+".service", "--no-legend").Run()
	return err == nil
}

// GetKnownServices returns the status of all known services that exist on the system.
func GetKnownServices() []ServiceStatus {
	var services []ServiceStatus
	for _, name := range KnownServices {
		if ServiceExists(name) {
			services = append(services, GetServiceStatus(name))
		}
	}
	return services
}

// ServiceActionCmd returns an exec.Cmd for the given service action.
// Actions: start, stop, restart, enable, disable
func ServiceActionCmd(name, action string) *exec.Cmd {
	return exec.Command("sudo", "systemctl", action, name)
}

// ServiceStatusCmd returns an exec.Cmd to show service status.
func ServiceStatusCmd(name string) *exec.Cmd {
	return exec.Command("systemctl", "status", name, "--no-pager")
}

// ListAllServices returns all service names on the system.
func ListAllServices() ([]string, error) {
	out, err := exec.Command("bash", "-c",
		"systemctl list-unit-files --type=service --no-pager --no-legend | awk '{print $1}' | sed 's/\\.service$//' | sort").Output()
	if err != nil {
		return nil, err
	}

	var services []string
	for _, line := range strings.Split(strings.TrimSpace(string(out)), "\n") {
		if line != "" {
			services = append(services, line)
		}
	}
	return services, nil
}
