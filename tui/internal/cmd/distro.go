package cmd

import (
	"bufio"
	"os"
	"os/exec"
	"strings"
)

// DistroType represents the Linux distribution family.
type DistroType string

const (
	DistroArch    DistroType = "arch"
	DistroDebian  DistroType = "debian"
	DistroFedora  DistroType = "fedora"
	DistroUnknown DistroType = "unknown"
)

// DistroInfo holds detected distribution details.
type DistroInfo struct {
	Type       DistroType
	Name       string
	PkgMgr     string
	PkgInstall string
	PkgUpdate  string
}

// knownIDs maps /etc/os-release ID to distro type.
var knownIDs = map[string]DistroType{
	"arch":        DistroArch,
	"manjaro":     DistroArch,
	"endeavouros": DistroArch,
	"garuda":      DistroArch,
	"artix":       DistroArch,
	"cachyos":     DistroArch,
	"ubuntu":      DistroDebian,
	"pop":         DistroDebian,
	"debian":      DistroDebian,
	"linuxmint":   DistroDebian,
	"elementary":  DistroDebian,
	"zorin":       DistroDebian,
	"fedora":      DistroFedora,
	"rhel":        DistroFedora,
	"centos":      DistroFedora,
	"rocky":       DistroFedora,
	"alma":        DistroFedora,
}

// DetectDistro parses /etc/os-release and returns distro info.
func DetectDistro() DistroInfo {
	info := DistroInfo{Type: DistroUnknown, Name: "Unknown"}

	fields := parseOSRelease()
	id := strings.ToLower(fields["ID"])
	name := fields["NAME"]
	idLike := strings.ToLower(fields["ID_LIKE"])

	if name != "" {
		info.Name = strings.Trim(name, "\"")
	}

	if dt, ok := knownIDs[id]; ok {
		info.Type = dt
	} else if strings.Contains(idLike, "arch") {
		info.Type = DistroArch
	} else if strings.Contains(idLike, "debian") || strings.Contains(idLike, "ubuntu") {
		info.Type = DistroDebian
	} else if strings.Contains(idLike, "fedora") || strings.Contains(idLike, "rhel") {
		info.Type = DistroFedora
	} else {
		info.Type = detectByCommand()
	}

	switch info.Type {
	case DistroArch:
		info.PkgMgr = "pacman"
		info.PkgInstall = "sudo pacman -S --noconfirm --needed"
		info.PkgUpdate = "sudo pacman -Syu"
	case DistroDebian:
		info.PkgMgr = "apt"
		info.PkgInstall = "sudo apt install -y"
		info.PkgUpdate = "sudo apt update && sudo apt upgrade -y"
	case DistroFedora:
		info.PkgMgr = "dnf"
		info.PkgInstall = "sudo dnf install -y"
		info.PkgUpdate = "sudo dnf upgrade -y"
	}

	return info
}

func parseOSRelease() map[string]string {
	fields := make(map[string]string)

	f, err := os.Open("/etc/os-release")
	if err != nil {
		return fields
	}
	defer f.Close()

	scanner := bufio.NewScanner(f)
	for scanner.Scan() {
		line := scanner.Text()
		if k, v, ok := strings.Cut(line, "="); ok {
			fields[k] = strings.Trim(v, "\"")
		}
	}
	// Check for scanner errors (e.g., line too long)
	if err := scanner.Err(); err != nil {
		return fields
	}
	return fields
}

func detectByCommand() DistroType {
	if _, err := exec.LookPath("pacman"); err == nil {
		return DistroArch
	}
	if _, err := exec.LookPath("apt"); err == nil {
		return DistroDebian
	}
	if _, err := exec.LookPath("dnf"); err == nil {
		return DistroFedora
	}
	return DistroUnknown
}
