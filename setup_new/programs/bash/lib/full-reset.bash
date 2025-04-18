# SPDX-License-Identifier: CC0-1.0

if ! command -v reset > '/dev/null'; then
	return
fi

function full-reset() {
	if ! command -v reset > '/dev/null'; then
		printf '%s: reset: program missing\n' "${FUNCNAME[0]}" >&2
		return 27
	fi

	if (($# > 0)); then
		printf '%s: too many arguments: %i\n' "${FUNCNAME[0]}" $# >&2
		return 4
	fi

	cd || return
	unset -v TERM_TITLE_PREFIX TERM_TITLE || return
	reset
}
