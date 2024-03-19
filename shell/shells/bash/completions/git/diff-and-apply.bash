# SPDX-License-Identifier: CC0-1.0

if ! command -v git > '/dev/null' || ! command -v git-diff-and-apply > '/dev/null'; then
	return
fi

# for command usage, i.e.: `git diff-and-apply`
function _git_diff_and_apply() {
	local cmd

	for cmd in git_diff  __git_diff_main  _git_diff; do
		if ! command -v $cmd > '/dev/null'; then
			continue
		fi

		$cmd "$@"
		return
	done
}

# for direct usage, i.e.: `git-diff-and-apply`
if command -v __git_complete > '/dev/null'; then
	__git_complete git-diff-and-apply git_diff
fi
