package system

import (
	"os/exec"
	"sort"
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
	PID     string // main PID (empty if not running)
}

// GetServiceStatus returns the status of a single service.
func GetServiceStatus(name string) ServiceStatus {
	status := ServiceStatus{Name: name, Active: "unknown", Enabled: "unknown"}

	// Check if service exists (systemd >= 245 exits 0 even for missing units, so check stdout)
	if !ServiceExists(name) {
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

	// Get main PID
	if out, err := exec.Command("systemctl", "show", name, "--property=MainPID", "--value").Output(); err == nil {
		pid := strings.TrimSpace(string(out))
		if pid != "" && pid != "0" {
			status.PID = pid
		}
	}

	return status
}

// ServiceExists checks if a service unit file exists.
// We check stdout because systemd >= 245 exits 0 even when the unit is not found.
func ServiceExists(name string) bool {
	out, err := exec.Command("systemctl", "list-unit-files", name+".service", "--no-legend").Output()
	if err != nil {
		return false
	}
	return strings.Contains(string(out), name+".service")
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


// ListAllServices returns all service names on the system.
func ListAllServices() ([]string, error) {
	out, err := exec.Command("systemctl", "list-unit-files", "--type=service", "--no-pager", "--no-legend").Output()
	if err != nil {
		return nil, err
	}

	var services []string
	for _, line := range strings.Split(strings.TrimSpace(string(out)), "\n") {
		fields := strings.Fields(line)
		if len(fields) > 0 {
			name := strings.TrimSuffix(fields[0], ".service")
			if name != "" {
				services = append(services, name)
			}
		}
	}
	sort.Strings(services)
	return services, nil
}
