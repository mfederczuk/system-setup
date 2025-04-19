# SPDX-License-Identifier: CC0-1.0

#region checking for required programs

declare __dotfiles_bash_funcs_man__cmd

for __dotfiles_bash_funcs_man__cmd in man mktemp grep; do
	if ! command -v "$__dotfiles_bash_funcs_man__cmd" > '/dev/null'; then
		return
	fi
done

unset -v __dotfiles_bash_funcs_man__cmd

#endregion

#region checking for GNU mktemp

declare __dotfiles_bash_funcs_man__mktemp_version_info
__dotfiles_bash_funcs_man__mktemp_version_info="$(mktemp --version)" || return

if [[ ! "$__dotfiles_bash_funcs_man__mktemp_version_info" =~ ^'mktemp (GNU coreutils)' ]]; then
	return
fi

unset -v __dotfiles_bash_funcs_man__mktemp_version_info

#endregion

#region checking for GNU grep

declare __dotfiles_bash_funcs_man__grep_version_info
__dotfiles_bash_funcs_man__grep_version_info="$(grep --version)" || return

if [[ ! "$__dotfiles_bash_funcs_man__grep_version_info" =~ ^'grep (GNU grep)' ]]; then
	return
fi

unset -v __dotfiles_bash_funcs_man__grep_version_info

#endregion

function man() {
	local cmd
	for cmd in mktemp grep; do
		if ! command -v "$cmd" > '/dev/null'; then
			printf '%s: %s: program missing\n' "${FUNCNAME[0]}" "$cmd" >&2
			return
		fi
	done
	unset -v cmd

	case "$TERM" in
		('xterm'*|'rxvt'*)
			local tmpfile_path || return
			local -i exc || return

			if tmpfile_path="$(command mktemp)"; then
				if command man "$@" 1> "$tmpfile_path" 2> '/dev/null'; then
					command printf '\e]0;' ||
						{
							exc=$?
							command rm -f -- "$tmpfile_path"
							return $exc
						}

					if [ -n "$TERM_TITLE_PREFIX" ]; then
						command printf '%s' "$TERM_TITLE_PREFIX: " ||
							{
								exc=$?
								command rm -f -- "$tmpfile_path"
								return $exc
							}
					fi

					{ command head -n5 -- "$tmpfile_path" |
						  command grep -Eo '^[0-9A-Za-z_.-]+\([0-9A-Za-z_.-]+\)' |
						  command head -n1 |
						  command tr '[:upper:]' '[:lower:]'; } ||
							{
								exc=$?
								command rm -f -- "$tmpfile_path"
								return $exc
							}

					command printf '\007' ||
						{
							exc=$?
							command rm -f -- "$tmpfile_path"
							return $exc
						}
				fi

				command rm -f -- "$tmpfile_path"
			fi

			command unset -v tmpfile_path
			;;
	esac

	command man "$@"
}
