# SPDX-License-Identifier: CC0-1.0

if ! command -v git > '/dev/null' || ! command -v git-iterate > '/dev/null'; then
	return
fi

# for command usage, i.e.: `git iterate`
function _git_iterate() {
	__git_complete_refs
}

# for direct usage, i.e.: `git-iterate`
complete -F _git_iterate git-iterate
