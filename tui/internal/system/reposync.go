package system

import "os/exec"

// The checkout is a read-only mirror of upstream, so local divergence is always
// discarded rather than merged. A plain --ff-only pull cannot recover once the
// remote history has been rewritten, which strands the clone permanently.
const repoSyncScript = `set -e
dir="$1"
if [ "$(git -C "$dir" rev-parse --is-shallow-repository)" = "true" ]; then
    git -C "$dir" fetch --unshallow --tags --force --prune origin
else
    git -C "$dir" fetch --tags --force --prune origin
fi
git -C "$dir" reset --hard origin/main`

// RepoSyncCmd returns a command that force-syncs dir to origin/main,
// unshallowing the clone and overwriting any local state.
func RepoSyncCmd(dir string) *exec.Cmd {
	return exec.Command("bash", "-c", repoSyncScript, "_", dir)
}
