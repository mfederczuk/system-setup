# SPDX-License-Identifier: CC0-1.0

function sortfile() {
	if (($# == 0)); then
		{
			printf '%s: missing arguments: <file>...\n' "${FUNCNAME[0]}"
			printf 'usage: %s <file>...\n' "${FUNCNAME[0]}"
		} >&2
		return 3
	fi

	local pathname || return

	for pathname in "$@"; do
		if [ ! -e "$pathname" ]; then
			printf '%s: %s: no such file\n' "${FUNCNAME[0]}" "$pathname" >&2
			return 24
		fi

		if [ ! -f "$pathname" ]; then
			local what || return
			if [ -d "$pathname" ]; then
				what='file' || return
			else
				what='regular file' || return
			fi
			readonly what || return

			printf '%s: %s: not a %s\n' "${FUNCNAME[0]}" "$pathname" "$what" >&2
			return 26
		fi

		if [ ! -r "$pathname" ]; then
			printf '%s: %s: permission denied: read permission missing\n' "${FUNCNAME[0]}" "$pathname" >&2
			return 77
		fi

		if [ ! -w "$pathname" ]; then
			printf '%s: %s: permission denied: write permission missing\n' "${FUNCNAME[0]}" "$pathname" >&2
			return 77
		fi
	done

	for pathname in "$@"; do
		sort -o "$pathname" -- "$pathname" || return
	done
}
