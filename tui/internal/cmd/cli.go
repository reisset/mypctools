package cmd

import (
	"fmt"
	"os"

	"github.com/reisset/mypctools/tui/internal/bundle"
	"github.com/reisset/mypctools/tui/internal/logging"
)

// ListBundles prints every bundle with its install state.
func ListBundles() int {
	fmt.Println("Bundles (✓ = installed):")
	fmt.Println()
	for _, b := range bundle.All() {
		mark := " "
		if bundle.IsInstalled(&b) {
			mark = "✓"
		}
		desc := b.Description
		if b.PlatformSuffix != "" {
			desc = fmt.Sprintf("%s (%s)", desc, b.PlatformSuffix)
		}
		fmt.Printf("  %s %-14s %s\n", mark, b.ID, desc)
	}
	return 0
}

// RunBundles installs or uninstalls each named bundle, in the order given.
// Every bundle is attempted even if an earlier one fails, so a fresh machine
// gets as far as it can. Returns the process exit code.
func RunBundles(rootDir, action string, ids []string) int {
	if len(ids) == 0 {
		fmt.Fprintf(os.Stderr, "Usage: mypctools %s <bundle>...\nRun 'mypctools list' to see available bundles.\n", action)
		return 1
	}
	if os.Geteuid() == 0 {
		fmt.Fprintln(os.Stderr, "Do not run as root. Use your normal user.")
		return 1
	}

	// Resolve everything up front so a typo can't half-configure a machine.
	var bundles []bundle.Bundle
	seen := map[string]bool{}
	for _, id := range ids {
		if seen[id] {
			continue
		}
		seen[id] = true
		b, ok := bundle.Find(id)
		if !ok {
			fmt.Fprintf(os.Stderr, "Unknown bundle: %s\nRun 'mypctools list' to see available bundles.\n", id)
			return 1
		}
		bundles = append(bundles, b)
	}

	var failed []string
	for i, b := range bundles {
		fmt.Printf("\n==> %s %s (%d/%d)\n", actionVerb(action), b.Name, i+1, len(bundles))
		if err := bundle.Run(rootDir, b, action); err != nil {
			fmt.Fprintf(os.Stderr, "==> %s %s failed: %v\n", b.Name, action, err)
			failed = append(failed, b.ID)
			logging.LogAction(fmt.Sprintf("Script %s %s failed", b.Name, action))
			continue
		}
		logging.LogAction(fmt.Sprintf("Script %s %s completed", b.Name, action))
	}

	if len(failed) > 0 {
		fmt.Fprintf(os.Stderr, "\n%s %d of %d. Failed: %v\n",
			actionPast(action), len(bundles)-len(failed), len(bundles), failed)
		return 1
	}
	if len(bundles) > 1 {
		fmt.Printf("\n%s %d of %d.\n", actionPast(action), len(bundles), len(bundles))
	}
	return 0
}

func actionVerb(action string) string {
	if action == "uninstall" {
		return "Uninstalling"
	}
	return "Installing"
}

func actionPast(action string) string {
	if action == "uninstall" {
		return "Uninstalled"
	}
	return "Installed"
}
