# Copyright (c) 2023 Michael Federczuk
# SPDX-License-Identifier: MPL-2.0 AND Apache-2.0

function cd..() {
	# region args

	local -i stepc || return

	case $# in
		(0)
			stepc=1 || return
			;;
		(1)
			if [ -z "$1" ]; then
				printf '%s: argument must not be empty\n' "${FUNCNAME[0]}" >&2
				return 9
			fi

			if [[ ! "$1" =~ ^['+-']?['0'-'9']+$ ]]; then
				printf '%s: %s: not an integer\n' "${FUNCNAME[0]}" "$1" >&2
				return 10
			fi

			stepc=$(("$1")) || return

			if ((stepc < 0)); then
				printf '%s: %s: out of range (< 0)\n' "${FUNCNAME[0]}" "$1" >&2
				return 11
			fi
			;;
		(*)
			{
				printf '%s: too many arguments: %i\n' "${FUNCNAME[0]}" $#
				printf 'usage: %s [<step count>]\n' "${FUNCNAME[0]}"
			} >&2
			return 4
			;;
	esac

	readonly stepc || return

	# endregion

	if ((stepc == 0)); then
		# no-op
		return
	fi

	# region building pathname

	local pathname || return

	local -i i || return
	for ((i = 0; i < stepc; ++i)); do
		if [ -n "$pathname" ]; then
			pathname+='/' || return
		fi

		pathname+='..' || return
	done
	unset -v i || return

	readonly pathname || return

	# endregion

	# shellcheck disable=2164
	cd -- "$pathname"
}

complete cd.. # disables completion
