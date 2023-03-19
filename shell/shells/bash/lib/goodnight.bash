# Copyright (c) 2023 Michael Federczuk
# SPDX-License-Identifier: MPL-2.0 AND Apache-2.0

# `goodnight` is an end-of-day function that performs the following steps:
# 1. (if available) updates the installed packages via the command `pkgsup` (see file 'pkgsup.bash')
# 2. (if available) creates a backup via the command `mkbak` (see <https://github.com/mfederczuk/mkbak>)
# 3. (if present) executes the file '~/goodnight_tasks'
# 4. (if available) updates the installed packages and shuts the system down via `upshut` (see file 'pkgsup.bash' again)
#  4a. if `upshut` is not available, shuts the system down via `shutdown`

if ! command -v trace_cmd > '/dev/null'; then
	return
fi

function goodnight() {
	#region checking environment

	if ! command -v trace_cmd > '/dev/null'; then
		printf '%s: trace_cmd: program missing\n' "${FUNCNAME[0]}" >&2
		return 27
	fi

	#region environment variables

	if [ -z "${HOME-}" ]; then
		printf '%s: HOME environment variable must not be unset or empty\n' "${FUNCNAME[0]}" >&2
		exit 48
	fi

	if [[ ! "$HOME" =~ ^'/' ]]; then
		printf '%s: %s: HOME environment variable must be an absolute path\n' "${FUNCNAME[0]}" "$HOME" >&2
		exit 49
	fi

	#endregion

	#endregion

	if (($# > 0)); then
		printf '%s: too many arguments: %i\n' "${FUNCNAME[0]}" $# >&2
		return 4
	fi

	#region checking tasks executable

	local tasks_executable_pathname || return
	tasks_executable_pathname="$HOME/goodnight_tasks" || return
	readonly tasks_executable_pathname

	local tasks_executable_present || return
	tasks_executable_present=false || return

	if [ -e "$tasks_executable_pathname" ]; then
		if [ ! -f "$tasks_executable_pathname" ]; then
			local what || return
			if [ -d "$tasks_executable_pathname" ]; then
				what='file' || return
			else
				what='regular file' || return
			fi
			readonly what || return

			printf '%s: %s: not a %s\n' "${FUNCNAME[0]}" "$tasks_executable_pathname" "$what" >&2
			return 26
		fi

		if [ ! -x "$tasks_executable_pathname" ]; then
			printf '%s: %s: permission denied: executable permissions missing\n' "${FUNCNAME[0]}" "$tasks_executable_pathname" >&2
			return 77
		fi

		tasks_executable_present=true || return
	fi

	readonly tasks_executable_present

	#endregion

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

	if $tasks_executable_present; then
		printf 'Executing goodnight tasks...\n' >&2 || return

		"$tasks_executable_pathname" || return

		printf 'Goodnight Tasks executed successfully\n' >&2 || return

		rm -- "$tasks_executable_pathname" || return
	fi

	if command -v upshut > '/dev/null'; then
		trace_cmd upshut
	else
		trace_cmd shutdown 0
	fi
}

complete goodnight
