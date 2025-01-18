# SPDX-License-Identifier: CC0-1.0

if ! command -v git > '/dev/null' || ! command -v git-append > '/dev/null'; then
	return
fi

# for command usage, i.e.: `git append`
function _git_append() {
	local cmd

	for cmd in git_commit  __git_commit_main  _git_commit; do
		if ! command -v $cmd > '/dev/null'; then
			continue
		fi

		$cmd "$@"
		return
	done
}

# for direct usage, i.e.: `git-append`
if command -v __git_complete > '/dev/null'; then
	__git_complete git-append git_commit
fi
