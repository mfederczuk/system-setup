# Copyright (c) 2023 Michael Federczuk
# SPDX-License-Identifier: MPL-2.0 AND Apache-2.0

function countfiles() {
	#region args

	local usage || return
	usage="usage: ${FUNCNAME[0]} [-T] [ [ -r | -f ] <directory> ]..." || return

	local -a pathname_specs || return
	pathname_specs=() || return

	local will_print_total || return
	will_print_total=true || return

	local recursively || return
	recursively=false || return

	local first_invalid_option_arg || return
	first_invalid_option_arg='' || return

	local help_specified || return
	help_specified=false || return

	local processing_options || return
	processing_options=true || return

	local arg || return
	for arg in "$@"; do
		if $processing_options && ((${#arg} >= 2)) && [[ "$arg" =~ ^'-' ]]; then
			if [ "$arg" = '--' ]; then
				processing_options=false || return
				continue
			fi

			if [[ "$arg" =~ ^'--' ]]; then
				local opt_id || return
				opt_id="${arg#"--"}" || return

				case "$opt_id" in
					('recursive') recursively=true                     || return ;;
					('flat')      recursively=false                    || return ;;
					('total')     will_print_total=true                || return ;;
					('no-total')  will_print_total=false               || return ;;
					('help')      help_specified=true                  || return ;;
					(*)           first_invalid_option_arg="--$opt_id" || return ;;
				esac

				unset -v opt_id || return

				continue
			fi

			local opt_ids || return
			opt_ids="${arg#"-"}" || return

			local -i i || return
			for ((i = 0; i < ${#opt_ids}; ++i)); do
				local opt_id || return
				opt_id="${opt_ids:i:1}" || return

				case "$opt_id" in
					('r') recursively=true                    || return ;;
					('f') recursively=false                   || return ;;
					('t') will_print_total=true               || return ;;
					('T') will_print_total=false              || return ;;
					('h') help_specified=true                 || return ;;
					(*)   first_invalid_option_arg="-$opt_id" || return ;;
				esac

				unset -v opt_id || return
			done
			unset -v i || return

			unset -v opt_ids || return

			continue
		fi

		if $recursively; then
			pathname_specs+=("r:$arg") || return
		else
			pathname_specs+=("f:$arg") || return
		fi
	done
	unset -v arg || return

	unset -v processing_options || return

	if $help_specified; then
		{
			printf '%s\n' "$usage"
			printf '    Count regular files of one or more directories.\n'
			printf '    If no directories are given, the current working directory is used.\n'
			printf '\n'
			printf '    Options:\n'
			printf '      -f, --flat       Do not count files in the following directories recursively. (default)\n'
			printf '      -r, --recursive  Count files in following directories recursively.\n'
			printf '\n'
			printf '      -t, --total      Print a total file count at the end if more than\n'
			printf '                        one directory is given. (default)\n'
			printf '      -T, --no-total   Do not print a total file count at the end.\n'
			printf '\n'
			printf '      -h, --help       Show this summary and exit successfully.\n'
		} >&2
		return 0
	fi
	unset -v help_specified

	if [ -n "$first_invalid_option_arg" ]; then
		{
			printf '%s: %s: invalid option\n' "${FUNCNAME[0]}" "$first_invalid_option_arg"
			printf '%s\n' "$usage"
		} >&2
		return 5
	fi
	unset -v first_invalid_option_arg || return

	if ((${#pathname_specs} == 0)); then
		if $recursively; then
			pathname_specs+=('r:.') || return
		else
			pathname_specs+=('f:.') || return
		fi
	fi
	unset -v recursively || return

	readonly will_print_total pathname_specs || return

	local -i i || return
	for ((i = 0; i < ${#pathname_specs[@]}; ++i)); do
		local pathname_spec || return
		pathname_spec="${pathname_specs[i]}" || return

		local pathname || return
		pathname="${pathname_spec:2}" || return

		if [ -z "$pathname" ]; then
			if ((${#pathname_specs[@]} == 1)); then
				printf '%s: argument must not be empty\n' "${FUNCNAME[0]}" >&2
			else
				printf '%s: argument %i: must not be empty\n' "${FUNCNAME[0]}" $((i + 1)) >&2
			fi

			printf '%s\n' "$usage" >&2

			return 9
		fi

		unset -v pathname pathname_spec || return
	done
	unset -v i || return

	unset -v usage || return

	#endregion

	local pathname_spec || return
	for pathname_spec in "${pathname_specs[@]}"; do
		local pathname || return
		pathname="${pathname_spec:2}" || return

		if [ ! -e "$pathname" ]; then
			printf '%s: %s: no such directory\n' "${FUNCNAME[0]}" "$pathname" >&2
			return 24
		fi

		if [ ! -d "$pathname" ]; then
			printf '%s: %s: not a directory\n' "${FUNCNAME[0]}" "$pathname" >&2
			return 26
		fi

		unset -v pathname || return
	done
	unset -v pathname_spec || return

	#region counting

	local -a file_counts || return
	file_counts=() || return

	local pathname_spec || return

	for pathname_spec in "${pathname_specs[@]}"; do
		local recursively || return
		if [ "${pathname_spec:0:1}" = 'r' ]; then
			recursively=true || return
		else
			recursively=false || return
		fi

		local pathname || return
		pathname="${pathname_spec:2}" || return

		if [[ "$pathname" =~ ^'-' ]]; then
			pathname="./$pathname" || return
		fi

		local -a find_flat_args || return
		find_flat_args=() || return

		if ! $recursively; then
			find_flat_args+=('-maxdepth' '1') || return
		fi

		local -i file_count || return
		file_count="$(find "$pathname" -mindepth 1 "${find_flat_args[@]}" -type f -exec printf x \; | wc -c)" || return

		file_counts+=("$file_count") || return

		unset -v file_count find_flat_args pathname recursively || return
	done

	unset -v pathname_spec || return

	readonly file_counts || return

	#endregion

	#region building output string

	if ((${#pathname_specs[@]} == 1)); then
		printf '%s\n' "${file_counts[0]}"
		return
	fi

	local out_str || return
	out_str='' || return

	local -i total_file_count || return
	total_file_count=0 || return

	local -i i || return
	for ((i = 0; i < ${#pathname_specs[@]}; ++i)); do
		local pathname_spec || return
		pathname_spec="${pathname_specs[i]}" || return

		local recursively || return
		if [ "${pathname_spec:0:1}" = 'r' ]; then
			recursively=true || return
		else
			recursively=false || return
		fi

		local pathname || return
		pathname="${pathname_spec:2}" || return

		local -i file_count || return
		file_count="${file_counts[i]}" || return

		((total_file_count += file_count)) || return

		if $recursively; then
			out_str+='(recursive) ' || return
		else
			out_str+='(flat) ' || return
		fi
		out_str+="$pathname: $file_count"$'\n' || return

		unset -v file_count pathname pathname_spec recursively || return
	done
	unset -v i || return

	readonly total_file_count || return

	if $will_print_total; then
		out_str+=$'\n'"total: $total_file_count"$'\n' || return
	fi

	readonly out_str || return

	#endregion

	printf '%s' "$out_str"
}

complete -o dirnames countfiles
