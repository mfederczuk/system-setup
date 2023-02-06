# Copyright (c) 2023 Michael Federczuk
# SPDX-License-Identifier: MPL-2.0 AND Apache-2.0

export RMCWD_WARN_FILE_COUNT=30

function rmcwd() {
	#region args

	local recursive force interactive || return
	recursive=false || return
	force=false || return
	interactive=false || return

	local first_invalid_opt_id || return
	first_invalid_opt_id='' || return

	local -i operand_count || return
	operand_count=0 || return

	local processing_opts || return
	processing_opts=true || return

	local arg || return
	for arg in "$@"; do
		if ! $processing_opts || [[ ! "$arg" =~ ^'-' ]] || ((${#arg} < 2)); then
			((++operand_count)) || return
			continue
		fi

		if [ "$arg" = '--' ]; then
			processing_opts=false || return
			continue
		fi

		if [[ "$arg" =~ ^'--' ]]; then
			{
				printf 'rmcwd: %s: invalid argument: long options are not supported\n' "$arg"
				printf 'usage: rmcwd [-r [-if]]\n'
			} >&2
			return 7
		fi

		local -i i || return

		for ((i = 1; i < ${#arg}; ++i)); do
			case "${arg:i:1}" in
				(['rR']) recursive=true   || return ;;
				('f')    force=true       || return ;;
				('i')    interactive=true || return ;;
				('h')
					{
						printf 'usage: rmcwd [-r [-if]]\n'
						printf '    Remove the current working directory.\n'
						printf '\n'
						printf '    Without the options -r or -R, the directory will only be removed if it is empty.\n'
						printf '\n'
						printf '    Options:\n'
						printf '      -r, -R  remove the directory contents recursively\n'
						printf '      -f      do not prompt for confirmation. Overrides previus instances of -i\n'
						printf '      -i      prompt before every removal. Overrides previous instances of -f\n'
					} >&2
					return
					;;
				(*)
					first_invalid_opt_id="${arg:i:1}" || return
					;;
			esac
		done

		unset -v i
	done
	unset -v arg || return

	unset -v processing_opts || return

	if ((operand_count > 0)); then
		{
			printf 'rmcwd: too many arguments: %i\n' $operand_count
			printf 'usage: rmcwd [-r [-if]]\n'
		}
		return 4
	fi
	unset -v operand_count || return

	if [ -n "$first_invalid_opt_id" ]; then
		{
			printf '-%s: invalid option\n' "$first_invalid_opt_id"
			printf 'usage: rmcwd [-r [-if]]\n'
		} >&2
		return 5
	fi
	unset -v first_invalid_opt_id || return

	readonly interactive force recursive || return

	#endregion


	local cwd_real_pathname || return
	if command -v realpath > '/dev/null'; then
		cwd_real_pathname="$(realpath . && printf x)" || return
		cwd_real_pathname="${cwd_real_pathname%$'\nx'}" || return
	else
		cwd_real_pathname="$(pwd -P && printf x)" || return
		cwd_real_pathname="${cwd_real_pathname%$'\nx'}" || return
	fi

	case "$cwd_real_pathname" in
		('/')
			printf 'rmcwd: refusing to remove root\n' >&2
			return 48
			;;
		("${HOME-}")
			printf 'rmcwd: refusing to remove the home directory\n' >&2
			return 48
			;;
		("${XDG_CONFIG_HOME-}")
			printf 'rmcwd: refusing to remove the XDG_CONFIG_HOME base directory\n' >&2
			return 48
			;;
		("${XDG_DATA_HOME-}")
			printf 'rmcwd: refusing to remove the XDG_DATA_HOME base directory\n' >&2
			return 48
			;;
		("${XDG_CACHE_HOME-}")
			printf 'rmcwd: refusing to remove the XDG_CACHE_HOME base directory\n' >&2
			return 48
			;;
	esac

	unset -v cwd_real_pathname || return


	local target_pathname || return
	target_pathname="$(pwd -L && printf x)" || return
	target_pathname="${target_pathname%$'\nx'}" || return
	readonly target_pathname || return

	if [[ ! "$target_pathname" =~ ^'/' ]]; then
		printf 'rmcwd: emergency stop: retrieved current working directory pathname is not absolute\n' >&2
		return 123
	fi


	local target_parent_dir_pathname || return
	target_parent_dir_pathname="$(dirname "$target_pathname" && printf x)" || return
	target_parent_dir_pathname="${target_parent_dir_pathname%$'\nx'}" || return
	readonly target_parent_dir_pathname || return


	cd "$target_parent_dir_pathname" ||
		cd '..' ||
		cd ||
		cd '/' ||
		return


	if [ -L "$target_pathname" ]; then
		declare -i exc || return
		exc=0 || return

		printf "Only removing the symlink '%s'.\\n" "$target_pathname" >&2

		rm "$target_pathname" ||
			{
				exc=$? || true
				cd "$target_pathname" &> '/dev/null' || true
			}

		return $exc
	fi


	if ! $recursive; then
		declare -i exc || return
		exc=0 || return

		rmdir "$target_pathname" ||
			{
				exc=$? || true
				cd "$target_pathname" &> '/dev/null' || true
			}

		return $exc
	fi


	local -i file_count_warn_threshhold || return
	file_count_warn_threshhold="${RMCWD_WARN_FILE_COUNT-0}" || return

	if ((file_count_warn_threshhold > 0)); then
		local -i cwd_file_count || return
		cwd_file_count="$(find "$target_pathname" -exec printf x \; | wc -c)" || return

		local ans || return

		if ((cwd_file_count >= file_count_warn_threshhold)); then
			printf "You're about to remove %i files and directories. Continue? [y/N] " $cwd_file_count >&2 || return

			read -r ans || return
		else
			ans='y' || return
		fi

		case "$ans" in
			(['yY'])
				# continue
				;;
			(*)
				cd "$target_pathname" &> '/dev/null' || true
				printf 'Aborted.\n' >&2
				return 49
				;;
		esac

		unset -v ans cwd_file_count || return
	fi

	unset -v file_count_warn_threshhold || return


	local -a rm_extra_opts || return
	rm_extra_opts=() || return

	if $force; then
		rm_extra_opts+=('-f') || return
	fi

	if $interactive; then
		rm_extra_opts+=('-i') || return
	fi

	readonly rm_extra_opts || return


	declare -i exc || return
	exc=0 || return

	rm "${rm_extra_opts[@]}" -R "$target_pathname" ||
		{
			exc=$? || true
			cd "$target_pathname" &> '/dev/null' || true
		}

	return $exc
}
