# SPDX-License-Identifier: CC0-1.0

if ! command -v git > '/dev/null' || ! command -v git-merge-into > '/dev/null'; then
	return
fi

function _git_merge_into() {
	if ! command -v __git_complete_refs > '/dev/null'; then
		return
	fi

	__git_complete_refs --mode='heads'
}
