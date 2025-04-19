# Copyright (c) 2023 Michael Federczuk
# SPDX-License-Identifier: MPL-2.0 AND Apache-2.0

if ! command -v normalize_pathname > '/dev/null'; then
	return
fi

function unwrap() {
	if ! command -v normalize_pathname > '/dev/null'; then
		printf '%s: normalize_pathname: program missing\n' "${FUNCNAME[0]}" >&2
		return 27
	fi

	#region args

	local usage || return
	usage="usage: ${FUNCNAME[0]} [--into=<destination_directory>] <directory>..."

	local -a source_directory_pathnames || return
	source_directory_pathnames=() || return

	local dest_pathname_explicitly_specified || return
	dest_pathname_explicitly_specified=false || return

	local dest_pathname || return
	dest_pathname='.' || return

	local first_option_id_with_dashes_with_excess_arg || return
	first_option_id_with_dashes_with_excess_arg='' || return

	local first_option_id_with_dashes_with_missing_arg || return
	first_option_id_with_dashes_with_missing_arg='' || return

	local first_invalid_option_id_with_dashes || return
	first_invalid_option_id_with_dashes='' || return

	local empty_long_option_id_specified || return
	empty_long_option_id_specified=false || return

	local help_option_specified || return
	help_option_specified=false || return

	local processing_options || return
	processing_options=true || return

	local -a args || return
	args=("$@") || return

	local -i arg_i || return
	for ((arg_i = 0; arg_i < ${#args[@]}; ++arg_i)); do
		local arg || return
		arg="${args[arg_i]}" || return

		if $processing_options && ((${#arg} >= 2)) && [[ "$arg" =~ ^'-' ]]; then
			case "$arg" in
				('--')
					processing_options=false || return
					;;
				('--=')
					empty_long_option_id_specified=true || return
					;;
				('--'*)
					local opt_id || return
					opt_id="${arg:2}" || return

					local opt_arg || return

					local opt_arg_exists || return
					opt_arg_exists=false || return

					local -i i || return
					for ((i = 0; i < ${#opt_id}; ++i)); do
						if [ "${opt_id:i:1}" = '=' ]; then
							opt_arg_exists=true || return
							opt_arg="${opt_id:i + 1}" || return
							opt_id="${opt_id:0:i}" || return
							break
						fi
					done
					unset -v i || return

					case "$opt_id" in
						('help')
							if ! $opt_arg_exists; then
								help_option_specified=true || return
							elif [ -z "$first_option_id_with_dashes_with_excess_arg" ]; then
								first_option_id_with_dashes_with_excess_arg="--$opt_id" || return
							fi
							;;
						('into')
							if ! $opt_arg_exists && (((arg_i + 1) < ${#args[@]})); then
								((++arg_i)) || return
								opt_arg_exists=true || return
								opt_arg="${args[arg_i]}" || return
							fi

							if $opt_arg_exists; then
								dest_pathname="$opt_arg" || return
								dest_pathname_explicitly_specified=true || return
							elif [ -z "$first_option_id_with_dashes_with_missing_arg" ]; then
								first_option_id_with_dashes_with_missing_arg="--$opt_id" || return
							fi
							;;
						(*)
							if [ -z "$first_invalid_option_id_with_dashes" ]; then
								first_invalid_option_id_with_dashes="--$opt_id" || return
							fi
							;;
					esac

					unset -v opt_arg_exists opt_arg opt_id || return
					;;
				(*)
					local opt_ids || return
					opt_ids="${arg:1}" || return

					local -i opt_id_i || return
					for ((opt_id_i = 0; i < ${#opt_ids}; ++opt_id_i)); do
						local opt_id || return
						opt_id="${opt_ids[opt_id_i]}" || return

						case "$opt_id" in
							('h')
								help_option_specified=true || return
								;;
							(*)
								if [ -z "$first_invalid_option_id_with_dashes" ]; then
									first_invalid_option_id_with_dashes="-$opt_id" || return
								fi
								;;
						esac

						unset -v opt_id || return
					done

					unset -v opt_id_i opt_ids || return
					;;
			esac
		else
			source_directory_pathnames+=("$arg") || return
		fi

		unset -v arg || return
	done
	unset -v arg_i || return

	unset -v args || return

	unset -v processing_options || return

	if $help_option_specified; then
		{
			printf '%s\n' "$usage"
			printf '    "Unwraps" one or more directories by first moving all entries of these\n'
			printf '    source directories into another destination directory and then removing\n'
			printf '    the now empty source directories.\n'
			printf '\n'
			printf '    If ALL specified source directory pathnames are both relative AND only\n'
			printf '    consist of a single pathname component (i.e.: only trailing slashes), then\n'
			printf '    the default destination directory will be the current working directory.\n'
			printf '    Otherwise, the destination directory must be specified explicitly with\n'
			printf '    the option --into.\n'
			printf '\n'
			printf '    Options:\n'
			printf '      --into=<directory>  Move files and directories into <directory>.\n'
			printf '\n'
			printf '      -h, --help  Print this summary and exit successfully.\n'
		} >&2
		return 0
	fi
	unset -v help_option_specified || return

	if $empty_long_option_id_specified; then
		printf '%s: --=: invalid argument\n' "${FUNCNAME[0]}" >&2
		return 7
	fi
	unset -v empty_long_option_id_specified || return

	if [ -n "$first_invalid_option_id_with_dashes" ]; then
		{
			printf '%s: %s: invalid option\n' "${FUNCNAME[0]}" "$first_invalid_option_id_with_dashes"
			printf '%s\n' "$usage"
		} >&2
		return 5
	fi
	unset -v first_invalid_option_id_with_dashes || return

	if [ -n "$first_option_id_with_dashes_with_missing_arg" ]; then
		{
			printf '%s: %s: missing argument\n' "${FUNCNAME[0]}" "$first_option_id_with_dashes_with_missing_arg"
			printf '%s\n' "$usage"
		} >&2
		return 3
	fi
	unset -v first_option_id_with_dashes_with_missing_arg || return

	if [ -n "$first_option_id_with_dashes_with_excess_arg" ]; then
		{
			printf '%s: %s: too many arguments: 1\n' "${FUNCNAME[0]}" "$first_option_id_with_dashes_with_excess_arg"
			printf '%s\n' "$usage"
		} >&2
		return 3
	fi
	unset -v first_option_id_with_dashes_with_excess_arg || return

	if [ -z "$dest_pathname" ]; then
		{
			printf '%s: --into: argument must not be empty\n' "${FUNCNAME[0]}"
			printf '%s\n' "$usage"
		} >&2
		return 9
	fi

	if ((${#source_directory_pathnames[@]} == 0)); then
		{
			printf '%s: missing arguments: <directory>...\n' "${FUNCNAME[0]}"
			printf '%s\n' "$usage"
		} >&2
		return 3
	fi

	unset -v usage || return

	local -i i || return
	for ((i = 0; i < ${#source_directory_pathnames[@]}; ++i)); do
		source_directory_pathnames[i]="$(normalize_pathname "${source_directory_pathnames[i]}" && printf x)" || return
		source_directory_pathnames[i]="${source_directory_pathnames[i]%x}" || return

		if [ "${source_directory_pathnames[i]}" != '/' ]; then
			source_directory_pathnames[i]="${source_directory_pathnames[i]%"/"}" || return
		fi
	done
	unset -v i || return

	dest_pathname="$(normalize_pathname "$dest_pathname" && printf x)" || return
	dest_pathname="${dest_pathname%x}" || return

	if [ "$dest_pathname" != '/' ]; then
		dest_pathname="${dest_pathname%"/"}" || return
	fi

	readonly dest_pathname dest_pathname_explicitly_specified source_directory_pathnames || return

	if ! $dest_pathname_explicitly_specified; then
		local source_directory_pathname || return

		for source_directory_pathname in "${source_directory_pathnames[@]}"; do
			if [[ "$source_directory_pathname" =~ ^('/'|[^'/']+'/'[^'/']+) ]]; then
				printf '%s: one or more source directories are either absolute or contain multiple components; --into must be specified\n' "${FUNCNAME[0]}" >&2
				return 13
			fi
		done

		unset -v source_directory_pathname || return
	fi

	#endregion

	#region prerequisites

	if [ ! -e "$dest_pathname" ]; then
		printf '%s: %s: no such directory\n' "${FUNCNAME[0]}" "$dest_pathname" >&2
		return 24
	fi

	if [ ! -d "$dest_pathname/" ]; then
		printf '%s: %s: not a directory\n' "${FUNCNAME[0]}" "$dest_pathname" >&2
		return 26
	fi

	local source_directory_pathname || return
	for source_directory_pathname in "${source_directory_pathnames[@]}"; do
		if [ "$source_directory_pathname" != '/' ]; then
			source_directory_pathname="${source_directory_pathname%"/"}" || return
		fi

		if [ ! -L "$source_directory_pathname" ] && [ ! -e "$source_directory_pathname" ]; then
			printf '%s: %s: no such directory\n' "${FUNCNAME[0]}" "$source_directory_pathname" >&2
			return 24
		fi

		if [ -L "$source_directory_pathname" ]; then
			printf '%s: %s: not a directory (is a symlink)\n' "${FUNCNAME[0]}" "$source_directory_pathname" >&2
			return 26
		fi

		if [ ! -d "$source_directory_pathname/" ]; then
			printf '%s: %s: not a directory\n' "${FUNCNAME[0]}" "$source_directory_pathname" >&2
			return 26
		fi

		if [ "$source_directory_pathname" = "$dest_pathname" ]; then
			printf '%s: %s: source and destination directories must not be the same\n' "${FUNCNAME[0]}" "$source_directory_pathname" >&2 || return
			return 14
		fi
	done
	unset -v source_directory_pathname || return

	#endregion

	local source_directory_pathname || return

	for source_directory_pathname in "${source_directory_pathnames[@]}"; do
		if [[ "$source_directory_pathname" =~ ^'-' ]]; then
			source_directory_pathname="./$source_directory_pathname" || return
		fi

		find "$source_directory_pathname" -mindepth 1 -maxdepth 1 \
		                                  -exec mv -i -- {} "$dest_pathname/" \; || return

		rmdir -- "$source_directory_pathname" || return
	done
}

complete -o dirnames unwrap
