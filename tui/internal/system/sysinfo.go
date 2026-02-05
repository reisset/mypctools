package system

import (
	"bufio"
	"fmt"
	"os"
	"os/exec"
	"os/user"
	"path/filepath"
	"strings"

	"github.com/reisset/mypctools/tui/internal/cmd"
)

// SystemInfo holds gathered system information.
type SystemInfo struct {
	User     string
	OS       string
	Host     string
	Kernel   string
	Uptime   string
	Packages string
	Shell    string
	DE       string
	Terminal string

	CPU    string
	GPU    string
	Memory string
	Disk   string
}

// GatherSystemInfo collects system info for display.
func GatherSystemInfo(distro cmd.DistroInfo) SystemInfo {
	info := SystemInfo{}

	// User@hostname
	if u, err := user.Current(); err == nil {
		hostname, _ := os.Hostname()
		info.User = u.Username + "@" + hostname
	}

	// OS
	info.OS = distro.Name

	// Host (product name)
	if data, err := os.ReadFile("/sys/devices/virtual/dmi/id/product_name"); err == nil {
		info.Host = strings.TrimSpace(string(data))
	}

	// Kernel
	if out, err := exec.Command("uname", "-r").Output(); err == nil {
		info.Kernel = strings.TrimSpace(string(out))
	}

	// Uptime
	if out, err := exec.Command("uptime", "-p").Output(); err == nil {
		info.Uptime = strings.TrimPrefix(strings.TrimSpace(string(out)), "up ")
	}

	// Packages
	info.Packages = countPackages(distro.Type)

	// Shell
	if shell := os.Getenv("SHELL"); shell != "" {
		info.Shell = filepath.Base(shell)
	}

	// DE
	info.DE = os.Getenv("XDG_CURRENT_DESKTOP")

	// Terminal
	info.Terminal = os.Getenv("TERM")

	// CPU
	info.CPU = getCPUModel()

	// GPU
	info.GPU = getGPUInfo()

	// Memory
	info.Memory = getMemoryInfo()

	// Disk
	info.Disk = getDiskInfo()

	return info
}

func countPackages(distroType cmd.DistroType) string {
	var parts []string

	// Native package count
	switch distroType {
	case cmd.DistroDebian:
		if out, err := exec.Command("bash", "-c", "dpkg --get-selections 2>/dev/null | wc -l").Output(); err == nil {
			count := strings.TrimSpace(string(out))
			if count != "0" {
				parts = append(parts, count+" (dpkg)")
			}
		}
	case cmd.DistroArch:
		if out, err := exec.Command("bash", "-c", "pacman -Q 2>/dev/null | wc -l").Output(); err == nil {
			count := strings.TrimSpace(string(out))
			if count != "0" {
				parts = append(parts, count+" (pacman)")
			}
		}
	case cmd.DistroFedora:
		if out, err := exec.Command("bash", "-c", "rpm -qa 2>/dev/null | wc -l").Output(); err == nil {
			count := strings.TrimSpace(string(out))
			if count != "0" {
				parts = append(parts, count+" (rpm)")
			}
		}
	}

	// Flatpak count
	if out, err := exec.Command("bash", "-c", "flatpak list --app 2>/dev/null | wc -l").Output(); err == nil {
		count := strings.TrimSpace(string(out))
		if count != "0" && count != "" {
			parts = append(parts, count+" (flatpak)")
		}
	}

	return strings.Join(parts, " + ")
}

func getCPUModel() string {
	f, err := os.Open("/proc/cpuinfo")
	if err != nil {
		return ""
	}
	defer f.Close()

	scanner := bufio.NewScanner(f)
	for scanner.Scan() {
		line := scanner.Text()
		if strings.HasPrefix(line, "model name") {
			if _, val, ok := strings.Cut(line, ":"); ok {
				return strings.TrimSpace(val)
			}
		}
	}
	return ""
}

func getGPUInfo() string {
	out, err := exec.Command("bash", "-c", "lspci 2>/dev/null | grep -i 'vga\\|3d\\|display' | head -1 | sed 's/.*: //'").Output()
	if err != nil {
		return ""
	}
	return strings.TrimSpace(string(out))
}

func getMemoryInfo() string {
	f, err := os.Open("/proc/meminfo")
	if err != nil {
		return ""
	}
	defer f.Close()

	var totalKB, availKB int64
	scanner := bufio.NewScanner(f)
	for scanner.Scan() {
		line := scanner.Text()
		if strings.HasPrefix(line, "MemTotal:") {
			fields := strings.Fields(line)
			if len(fields) >= 2 {
				totalKB = parseInt(fields[1])
			}
		}
		if strings.HasPrefix(line, "MemAvailable:") {
			fields := strings.Fields(line)
			if len(fields) >= 2 {
				availKB = parseInt(fields[1])
			}
		}
	}

	if totalKB == 0 {
		return ""
	}

	usedKB := totalKB - availKB
	usedGB := float64(usedKB) / 1024 / 1024
	totalGB := float64(totalKB) / 1024 / 1024

	return fmt.Sprintf("%.1fGB / %.1fGB", usedGB, totalGB)
}

func parseInt(s string) int64 {
	var n int64
	for _, c := range s {
		if c >= '0' && c <= '9' {
			n = n*10 + int64(c-'0')
		}
	}
	return n
}

func getDiskInfo() string {
	out, err := exec.Command("bash", "-c", "df -h / 2>/dev/null | awk 'NR==2 {print $3 \" / \" $2 \" (\" $5 \" used)\"}'").Output()
	if err != nil {
		return ""
	}
	return strings.TrimSpace(string(out))
}
