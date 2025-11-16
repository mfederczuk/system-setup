# SPDX-License-Identifier: CC0-1.0

if ! command -v clipboard > '/dev/null'; then
	return
fi

function _clipboard() {
	declare -ga COMPREPLY
	COMPREPLY=()

	if ((COMP_CWORD != 1)); then
		return
	fi

	# shellcheck disable=SC2034
	mapfile -t COMPREPLY < <(compgen -W 'copy clear paste' -- "${COMP_WORDS[1]}")
}

complete -F _clipboard clipboard
