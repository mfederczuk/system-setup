# SPDX-License-Identifier: CC0-1.0

# common typo of mine; insult me if i fat-finger it

if ! command -v git > '/dev/null'; then
	return
fi

declare __gti_insult_msg
__gti_insult_msg="You meant 'git', you absolute fridge, you"

function gti() {
	printf '%s\n' "${__gti_insult_msg-}" >&2
	return 1
}

function _gti() {
	if [[ "${COMP_LINE-}" =~ ^'gti'([[:space:]]+)?$ ]]; then
		COMPREPLY=("${__gti_insult_msg-}")
	fi
}

complete -F _gti gti
