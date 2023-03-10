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

#region completion

if [ -f "$PREFIX/share/bash-completion/completions/mkdir" ]; then
	# shellcheck disable=1091
	. "$PREFIX/share/bash-completion/completions/mkdir"
fi

declare __dotfiles_bash_funcs_sequence_commands__mkdir_complete
__dotfiles_bash_funcs_sequence_commands__mkdir_complete="$(complete | grep -E '^complete( .*)? mkdir$')"

if [ -n "$__dotfiles_bash_funcs_sequence_commands__mkdir_complete" ]; then
	eval "${__dotfiles_bash_funcs_sequence_commands__mkdir_complete}-cd"
fi

unset -v __dotfiles_bash_funcs_sequence_commands__mkdir_complete

#endregion
