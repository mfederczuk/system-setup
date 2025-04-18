# SPDX-License-Identifier: CC0-1.0

if ! command -v git > '/dev/null' || ! command -v git-prune-local-branches > '/dev/null'; then
	return
fi

# for command usage, i.e.: `git prune-local-branches`
function _git_prune_local_branches() {
	compopt +o bashdefault +o default
	__gitcomp
}

# for direct usage, i.e.: `git-prune-local-branches`
if command -v __git_complete > '/dev/null'; then
	function _git_prune_local_branches_completion() {
		__gitcomp
	}

	__git_complete git-prune-local-branches _git_prune_local_branches_completion
	compopt +o bashdefault +o default git-prune-local-branches
else
	complete git-prune-local-branches
fi
