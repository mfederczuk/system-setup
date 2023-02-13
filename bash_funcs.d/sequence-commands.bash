# SPDX-License-Identifier: CC0-1.0

function mkdir-cd() {
	#region args

	local pathname || return

	case $# in
		(0)
			{
				printf '%s: missing argument: <pathname>\n' "${FUNCNAME[0]}"
				printf 'usage: %s <pathname>\n' "${FUNCNAME[0]}"
			} >&2
			return 3
			;;
		(1)
			if [ -z "$1" ]; then
				printf '%s: argument must not be empty\n' "${FUNCNAME[0]}" >&2
				return 9
			fi

			pathname="$1" || return
			;;
		(*)
			{
				printf '%s: too many arguments: %i\n' "${FUNCNAME[0]}" $#
				printf 'usage: %s <pathname>\n' "${FUNCNAME[0]}"
			} >&2
			return 3
			;;
	esac

	readonly pathname || return

	#endregion

	# shellcheck disable=2164
	mkdir -p -- "$pathname" &&
		cd -- "$pathname"
}

if command -v codium > '/dev/null'; then
	function cd-codium() {
		if ! command -v codium > '/dev/null'; then
			printf '%s: codium: program missing\n' "${FUNCNAME[0]}" >&2
			return 27
		fi

		cd "$@" &&
			codium '.'
	}

	function mkdir-cd-codium() {
		if ! command -v codium > '/dev/null'; then
			printf '%s: codium: program missing\n' "${FUNCNAME[0]}" >&2
			return 27
		fi

		#region args

		local pathname || return

		case $# in
			(0)
				{
					printf '%s: missing argument: <pathname>\n' "${FUNCNAME[0]}"
					printf 'usage: %s <pathname>\n' "${FUNCNAME[0]}"
				} >&2
				return 3
				;;
			(1)
				if [ -z "$1" ]; then
					printf '%s: argument must not be empty\n' "${FUNCNAME[0]}" >&2
					return 9
				fi

				pathname="$1" || return
				;;
			(*)
				{
					printf '%s: too many arguments: %i\n' "${FUNCNAME[0]}" $#
					printf 'usage: %s <pathname>\n' "${FUNCNAME[0]}"
				} >&2
				return 3
				;;
		esac

		readonly pathname || return

		#endregion

		mkdir -p -- "$pathname" &&
			cd -- "$pathname" &&
			codium '.'
	}
fi

#region completion

if [ -f '/usr/share/bash-completion/completions/mkdir' ]; then
	# shellcheck disable=1091
	. '/usr/share/bash-completion/completions/mkdir'
fi

declare __dotfiles_bash_funcs_sequence_commands__mkdir_complete
__dotfiles_bash_funcs_sequence_commands__mkdir_complete="$(complete | grep -E '^complete( .*)? mkdir$')"

eval "${__dotfiles_bash_funcs_sequence_commands__mkdir_complete}-cd"

if command -v cd-codium > '/dev/null'; then
	if [ -f '/usr/share/bash-completion/completions/cd' ]; then
		# shellcheck disable=1091
		. '/usr/share/bash-completion/completions/cd'
	fi

	declare __dotfiles_bash_funcs_sequence_commands__cd_complete
	__dotfiles_bash_funcs_sequence_commands__cd_complete="$(complete | grep -E '^complete( .*)? cd$')"

	eval "${__dotfiles_bash_funcs_sequence_commands__cd_complete}-codium"

	unset -v __dotfiles_bash_funcs_sequence_commands__cd_complete
fi

if command -v mkdir-cd-codium > '/dev/null'; then
	eval "${__dotfiles_bash_funcs_sequence_commands__mkdir_complete}-cd-codium"
fi

#endregion
