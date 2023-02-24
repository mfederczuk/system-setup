# Copyright (c) 2023 Michael Federczuk
# SPDX-License-Identifier: MPL-2.0 AND Apache-2.0

#region checking for required programs

declare __dotfiles_bash_funcs_gotmp__cmd

for __dotfiles_bash_funcs_gotmp__cmd in mktemp readlink_portable; do
	if ! command -v "$__dotfiles_bash_funcs_gotmp__cmd" > '/dev/null'; then
		return
	fi
done

unset -v __dotfiles_bash_funcs_gotmp__cmd

#endregion

#region checking for GNU mktemp

declare __dotfiles_bash_funcs_man__mktemp_version_info
__dotfiles_bash_funcs_man__mktemp_version_info="$(mktemp --version)" || return

if [[ ! "$__dotfiles_bash_funcs_man__mktemp_version_info" =~ ^'mktemp (GNU coreutils)' ]]; then
	return
fi

unset -v __dotfiles_bash_funcs_man__mktemp_version_info

#endregion

# TODO: this deseparately needs to be in its own executable file so that we can properly use `trap`

function gotmp() {
	#region checking for required programs

	local cmd || return

	for cmd in mktemp readlink_portable; do
		if ! command -v "$cmd" > '/dev/null'; then
			printf '%s: %s: program missing\n' "${FUNCNAME[0]}" "$cmd" >&2
			return 27
		fi
	done

	unset -v cmd || return

	#endregion

	if (($# > 0)); then
		printf '%s: too many arguments: %i\n' "${FUNCNAME[0]}" $# >&2
		return 4
	fi

	local cwd || return
	cwd="$(pwd -P && printf x)" || return
	cwd="${cwd%$'\nx'}" || return
	readonly cwd || return

	local -i exc || return
	exc=0 || return

	local tmp_dir_pathname || return
	tmp_dir_pathname="$(mktemp --directory)" || return
	readonly tmp_dir_pathname ||
		{
			exc=$?
			rm -rf -- "$tmp_dir_pathname"
			return $exc
		}

	cd "$tmp_dir_pathname" ||
		{
			exc=$?
			rm -rf -- "$tmp_dir_pathname"
			return $exc
		}

	{
		local tmp_dir_pathname_quoted &&
			if command -v pretty_quote > '/dev/null'; then
				tmp_dir_pathname_quoted="$(pretty_quote "$tmp_dir_pathname")"
			elif command -v quote > '/dev/null'; then
				tmp_dir_pathname_quoted="$(quote "$tmp_dir_pathname")"
			else
				tmp_dir_pathname_quoted="'$tmp_dir_pathname'"
			fi &&
			{
				printf 'Created directory \e[34m%s\e[0m\n' "$tmp_dir_pathname_quoted" &&
					printf 'A new shell instance has been started. Exit it to stop working in the temporary directory\n'
			} >&2
	} ||
		{
			exc=$?
			rm -rf -- "$tmp_dir_pathname"
			return $exc
		}

	"${SHELL:-"sh"}" ||
		{
			exc=$?
			rm -rf -- "$tmp_dir_pathname"
			return $exc
		}

	cd -- "$cwd" ||
		cd - ||
		cd ||
		cd '..' ||
		cd '/' ||
		{
			exc=$?
			printf 'Error leaving the temporary directory; it was not removed\n' >&2
			return $exc
		}

	{
		local is_tmp_dir_in_use &&
			is_tmp_dir_in_use=false &&

			local proc_dir_pathname &&
			for proc_dir_pathname in '/proc/'*; do
				{
					local -i pid &&
						if [ ! -d "$proc_dir_pathname" ] || [[ ! "$proc_dir_pathname" =~ ^'/proc/'([1-9][0-9]*)$ ]]; then
							continue
						fi &&

						pid="${BASH_REMATCH[1]}" &&

						if [ ! -r "$proc_dir_pathname/cwd" ]; then
							continue
						fi &&

						local proc_cwd_pathname &&
						proc_cwd_pathname="$(readlink_portable "$proc_dir_pathname/cwd" && printf x)" &&
						proc_cwd_pathname="${proc_cwd_pathname%x}" &&

						case "$proc_cwd_pathname" in
							("$tmp_dir_pathname")
								is_tmp_dir_in_use=true &&
									printf 'Process with PID %i still uses the temporary directory as its current working directory.\n' $pid >&2
								;;
							("$tmp_dir_pathname/"*)
								is_tmp_dir_in_use=true &&
									printf 'Process with PID %i still uses a child of the temporary directory as its current working directory.\n' $pid >&2
								;;
						esac &&

						unset -v proc_cwd_pathname pid
				} ||
					{
						exc=$?
						break
					}
			done &&
			unset -v proc_dir_pathname
	} ||
		exc=$?

	if ((exc != 0)); then
		rm -rf -- "$tmp_dir_pathname"
		return $exc
	fi

	if $is_tmp_dir_in_use; then
		local ans &&
			{
				read -rp 'Other processes still use the temporary directory. Remove it regardldess? [y/N] ' ans ||
					ans='n'
			} &&

			case "$ans" in
				(['yY']*)
					# continue
					;;
				('')
					printf 'Since other processes still use the temporary directory, it will not be removed.\n' >&2
					return
					;;
			esac &&

			unset -v ans
	fi

	rm -rf -- "$tmp_dir_pathname" || return
	printf 'Recursively removed directory \e[34m%s\e[0\n' "$tmp_dir_pathname_quoted" >&2
}

complete gotmp
