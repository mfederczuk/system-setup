# Copyright (c) 2023 Michael Federczuk
# SPDX-License-Identifier: MPL-2.0 AND Apache-2.0

if ! command -v trace_cmd > '/dev/null'; then
	return
fi

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
