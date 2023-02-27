# SPDX-License-Identifier: CC0-1.0

if ! command -v xclip > '/dev/null'; then
	return
fi

function xcopystr() {
	if ! command -v xclip > '/dev/null'; then
		printf '%s: xclip: program missing\n' "${FUNCNAME[0]}" >&2
		return 27
	fi

	#region args

	local str || return

	case $# in
		(0)
			{
				printf '%s: missing argument: <str>\n' "${FUNCNAME[0]}"
				printf 'usage: %s <str>\n' "${FUNCNAME[0]}"
			} >&2
			return 3
			;;
		(1)
			str="$1" || return
			;;
		(*)
			{
				printf '%s: too many arguments: %i\n' "${FUNCNAME[0]}" $(($# - 1))
				printf 'usage: %s <str>\n' "${FUNCNAME[0]}"
			} >&2
			return 4
			;;
	esac

	readonly str || return

	#endregion

	xclip -selection clipboard -i < <(printf '%s' "$str")
}

function xcopyfile() {
	if ! command -v xclip > '/dev/null'; then
		printf '%s: xclip: program missing\n' "${FUNCNAME[0]}" >&2
		return 27
	fi

	#region args

	local input_source || return

	case $# in
		(0)
			input_source='stdin:' || return
			;;
		(1)
			if [ -z "$1" ]; then
				printf '%s: argument must not be empty\n' "${FUNCNAME[0]}" >&2
				return 9
			fi

			if [ "$1" = '-' ]; then
				input_source='stdin:' || return
			else
				input_source="file:$1" || return
			fi
			;;
		(*)
			{
				printf '%s: too many arguments: %i\n' "${FUNCNAME[0]}" $(($# - 1))
				printf 'usage: %s <file>\n' "${FUNCNAME[0]}"
			} >&2
			return 4
			;;
	esac

	readonly input_source

	#endregion

	local -a pathname_args || return
	pathname_args=() || return

	if [[ "$input_source" =~ ^'file:' ]]; then
		local input_file_pathname || return
		input_file_pathname="${input_source#"file:"}" || return

		if [ ! -e "$input_file_pathname" ]; then
			printf '%s: %s: no such file\n' "${FUNCNAME[0]}" "$input_file_pathname" >&2
			return 24
		fi

		if [ -d "$input_file_pathname" ]; then
			printf '%s: %s: not a file\n' "${FUNCNAME[0]}" "$input_file_pathname" >&2
			return 26
		fi

		pathname_args+=("$input_file_pathname") || return
		unset -v input_file_pathname || return
	fi

	readonly pathname_args || return

	xclip -selection clipboard -i "${pathname_args[@]}"
}

function xpaste() {
	if ! command -v xclip > '/dev/null'; then
		printf '%s: xclip: program missing\n' "${FUNCNAME[0]}" >&2
		return 27
	fi

	if (($# > 0)); then
		printf '%s: too many arguments: %i\n' "${FUNCNAME[0]}" $# >&2
		return 4
	fi

	local -a targets || return
	mapfile -t targets < <(xclip -selection clipboard -t TARGETS -o) || return
	readonly targets || return

	# important: don't use targets 'text/plain;charset=utf-8' or 'text/plain', they turn LF into CR LF !

	local requested_target existing_targets || return

	for requested_target in 'UTF8_STRING' 'STRING' 'TEXT' 'COMPOUND_TEXT' 'text/html'; do
		for existing_targets in "${targets[@]}"; do
			if [ "$existing_targets" = "$requested_target" ]; then
				xclip -selection clipboard -t "$requested_target" -o
				return
			fi
		done
	done

	return 1
}

function xclip-clear() {
	if ! command -v xclip > '/dev/null'; then
		printf '%s: xclip: program missing\n' "${FUNCNAME[0]}" >&2
		return 27
	fi

	if (($# > 0)); then
		printf '%s: too many arguments: %i\n' "${FUNCNAME[0]}" $# >&2
		return 4
	fi

	xclip -selection clipboard -i '/dev/null'
}

function xclip-sort() {
	if ! command -v xclip > '/dev/null'; then
		printf '%s: xclip: program missing\n' "${FUNCNAME[0]}" >&2
		return 27
	fi

	xclip -selection clipboard -o |
		sort "$@" |
		xclip -selection clipboard -i
}
