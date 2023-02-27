# SPDX-License-Identifier: CC0-1.0

if ! command -v xdg-open > '/dev/null'; then
	return
fi

function xdg() {
	if ! command -v xdg-open > '/dev/null'; then
		printf '%s: xdg-open: program missing\n' "${FUNCNAME[0]}" >&2
		return 27
	fi

	if (($# == 0)); then
		{
			printf '%s: missing arguments: <file | URL>...\n' "${FUNCNAME[0]}"
			printf 'usage: %s <file | URL>...\n' "${FUNCNAME[0]}"
		} >&2
		return 3
	fi

	local arg || return

	#region options

	local -a options || return
	options=() || return

	for arg in "$@"; do
		if [[ "$arg" =~ ^'-' ]]; then
			options+=("$arg") || return
		fi
	done

	if ((${#options[@]} > 0)); then
		xdg-open "${options[@]}"
		return
	fi

	unset -v options || return

	#endregion

	for arg in "$@"; do
		xdg-open "$arg" || return
	done
}
