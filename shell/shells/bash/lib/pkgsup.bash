# Copyright (c) 2023 Michael Federczuk
# SPDX-License-Identifier: MPL-2.0 AND Apache-2.0

if ! command -v trace_cmd > '/dev/null'; then
	return
fi

#region distinct package managers

# BASE: <cmd>-up comamnd for system's native package manager

if command -v flatpak > '/dev/null'; then
	function flatpak-up() {
		#region checking for required programs

		local cmd || return

		for cmd in flatpak trace_cmd; do
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

		trace_cmd flatpak update >&2
	}

	complete flatpak-up
fi

if command -v npm > '/dev/null' && command -v try_as_root > '/dev/null'; then
	function npm-up() {
		#region checking for required programs

		local cmd || return

		for cmd in npm trace_cmd try_as_root; do
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

		#region collecting globally installed packages

		local -a packages || return
		packages=() || return

		local line || return

		while read -r line; do
			if [[ ! "$line" =~ ^('├── '|'└── ')(.+)'@'[^'@']+$ ]]; then
				continue
			fi

			packages+=("${BASH_REMATCH[2]}") || return
		done < <(npm list --global --depth=0 |
			         # removes first line
			         tail -n +2)

		unset -v line || return

		readonly packages

		#endregion

		if ((${#packages[@]} == 0)); then
			# no-op
			return
		fi

		trace_cmd try_as_root npm install --global "${packages[@]}" >&2
	}

	complete npm-up
fi

#endregion

#region pkgsup

declare __dotfiles_bash_funcs_pkgsup__any_up_commands_present
__dotfiles_bash_funcs_pkgsup__any_up_commands_present=false

declare __dotfiles_bash_funcs_pkgsup__up_cmd

for __dotfiles_bash_funcs_pkgsup__up_cmd in {dnf,apt,flatpak,npm}-up; do
	if command -v "$__dotfiles_bash_funcs_pkgsup__up_cmd" > '/dev/null'; then
		__dotfiles_bash_funcs_pkgsup__any_up_commands_present=true
		break
	fi
done

unset -v __dotfiles_bash_funcs_pkgsup__up_cmd

if $__dotfiles_bash_funcs_pkgsup__any_up_commands_present; then
	# shellcheck disable=2120
	function pkgsup() {
		if ! command -v trace_cmd > '/dev/null'; then
			printf '%s: trace_cmd: program missing\n' "${FUNCNAME[0]}" >&2
			return 27
		fi

		if (($# > 0)); then
			printf '%s: too many arguments: %i\n' "${FUNCNAME[0]}" $# >&2
			return 4
		fi

		local -ar package_managers=(
			# BASE: system's native package manager command
			flatpak
			npm
		) || return

		local print_separator || return
		print_separator=false || return

		local package_manager || return
		for package_manager in "${package_managers[@]}"; do
			if ! command -v "$package_manager-up" > '/dev/null'; then
				continue
			fi

			if $print_separator; then
				printf '\n\n\n' >&2 || return
			fi

			print_separator=true || return

			trace_cmd "$package_manager-up" || return
		done
	}

	complete pkgsup
fi

unset -v __dotfiles_bash_funcs_pkgsup__any_up_commands_present

#endregion

#region upshut

if command -v pkgsup > '/dev/null'; then
	function upshut() {
		#region checking for required programs

		local cmd || return

		for cmd in dnf trace_cmd pkgsup; do
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

		trace_cmd pkgsup || return

		printf 'Shutting down in 3 seconds... (Ctrl+C to cancel)\n' >&2 || return
		sleep 3 || return

		trace_cmd shutdown 0
	}

	complete upshut
fi

#endregion

#region goodnight

function goodnight() {
	if ! command -v trace_cmd > '/dev/null'; then
		printf '%s: trace_cmd: program missing\n' "${FUNCNAME[0]}" >&2
		return 27
	fi

	if (($# > 0)); then
		printf '%s: too many arguments: %i\n' "${FUNCNAME[0]}" $# >&2
		return 4
	fi

	cd || return

	if command -v pkgsup > '/dev/null'; then
		trace_cmd pkgsup || return
	fi

	if command -v mkbak > '/dev/null'; then
		local today new_backup_archive_filename || return

		today="$(date +'%Y-%m-%H')" || return
		new_backup_archive_filename="$today.tar.gz" || return

		if [ -e "$new_backup_archive_filename" ]; then
			# we're assuming GNU system here, because otherwise it'd be a pain trying to get the birth/mod time in hours
			# of a file
			# TODO: find a way to do this with POSIX without wanting to blow my brains out

			local existing_backup_archive_filename existing_backup_archive_file_timestamp existing_backup_archive_file_hour current_hour || return

			existing_backup_archive_filename="$new_backup_archive_filename" || return

			# %W -> birth time in unix epoch
			existing_backup_archive_file_timestamp="$(stat --format='%W' -- "$existing_backup_archive_filename")" || return

			if [ "$existing_backup_archive_file_timestamp" -eq 0 ]; then
				# %Y -> last mod time in unix epoch
				existing_backup_archive_file_timestamp="$(stat --format='%Y' -- "$existing_backup_archive_filename")" || return
			fi

			existing_backup_archive_file_hour="$(date --date="@$existing_backup_archive_file_timestamp" +'%H')" || return

			current_hour="$(date +'%H')" || return

			if [ "$current_hour" != "$existing_backup_archive_file_hour" ]; then
				mv -- "$existing_backup_archive_filename" \
				      "${existing_backup_archive_filename%".tar.gz"}_H$existing_backup_archive_file_hour.tar.gz" || return

				new_backup_archive_filename="${new_backup_archive_filename%".tar.gz"}_H$current_hour.tar.gz" || return
			fi

			unset -v current_hour existing_backup_archive_file_hour existing_backup_archive_file_timestamp existing_backup_archive_filename || return
		fi

		trace_cmd mkbak --output="$new_backup_archive_filename" || return

		unset -v new_backup_archive_filename today || return
	fi

	if command -v upshut > '/dev/null'; then
		trace_cmd upshut
	else
		trace_cmd shutdown 0
	fi
}

complete goodnight

#endregion
