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

// unitFileStates maps every installed service unit to its enable state.
func unitFileStates() (map[string]string, error) {
	out, err := exec.Command("systemctl", "list-unit-files", "--type=service", "--no-pager", "--no-legend").Output()
	if err != nil {
		return nil, err
	}
	states := make(map[string]string)
	for _, line := range strings.Split(strings.TrimSpace(string(out)), "\n") {
		fields := strings.Fields(line)
		if len(fields) < 2 {
			continue
		}
		states[strings.TrimSuffix(fields[0], ".service")] = fields[1]
	}
	return states, nil
}

// activeStates maps every loaded service unit to its active state.
// Units missing from the result are installed but not loaded.
func activeStates() map[string]string {
	out, err := exec.Command("systemctl", "list-units", "--type=service", "--all", "--plain", "--no-pager", "--no-legend").Output()
	if err != nil {
		return nil
	}
	states := make(map[string]string)
	for _, line := range strings.Split(strings.TrimSpace(string(out)), "\n") {
		fields := strings.Fields(line)
		if len(fields) < 3 {
			continue
		}
		states[strings.TrimSuffix(fields[0], ".service")] = fields[2]
	}
	return states
}

func listedStatus(name, enabled string, active map[string]string) ServiceStatus {
	state := active[name]
	if state == "" {
		state = "inactive"
	}
	return ServiceStatus{Name: name, Active: state, Enabled: enabled}
}

// GetKnownServices returns the status of all known services installed on the system.
func GetKnownServices() []ServiceStatus {
	enabled, err := unitFileStates()
	if err != nil {
		return nil
	}
	active := activeStates()

	var services []ServiceStatus
	for _, name := range KnownServices {
		if state, ok := enabled[name]; ok {
			services = append(services, listedStatus(name, state, active))
		}
	}
	return services
}

// ServiceActionCmd returns an exec.Cmd for the given service action.
// Actions: start, stop, restart, enable, disable
func ServiceActionCmd(name, action string) *exec.Cmd {
	return exec.Command("sudo", "systemctl", action, name)
}

// GetAllServices returns the status of every installed service, sorted by name.
func GetAllServices() ([]ServiceStatus, error) {
	enabled, err := unitFileStates()
	if err != nil {
		return nil, err
	}
	active := activeStates()

	services := make([]ServiceStatus, 0, len(enabled))
	for name, state := range enabled {
		services = append(services, listedStatus(name, state, active))
	}
	sort.Slice(services, func(i, j int) bool { return services[i].Name < services[j].Name })
	return services, nil
}
