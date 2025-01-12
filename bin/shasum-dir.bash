#!/bin/bash
# -*- sh -*-
# vim: syntax=sh
# code: language=shellscript

# Copyright (c) 2025 Michael Federczuk
# SPDX-License-Identifier: MPL-2.0 AND Apache-2.0

# TODO: empty directories (or more precisely, empty TREES) should not add towards the resulting hash

#region preamble

case "$-" in
	(*'i'*)
		if \command test -n "${BASH_VERSION-}"; then
			# using `eval` here in case a non-Bash shell tries to parse this branch even if the condition is false
			\command eval "\\command printf '%s: ' \"\${BASH_SOURCE[0]}\" >&2"
		fi

		\command printf 'script was called interactively\n' >&2
		return 124
		;;
esac

set -o errexit
set -o nounset
set -o pipefail

if [ -z "${BASH_VERSION-}" ]; then
	if [ "${0#/}" = "$0" ]; then
		argv0="$0"
	else
		argv0="$(basename -- "$0" && printf x)"
		argv0="${argv0%"$(printf '\nx')"}"
	fi
	readonly argv0

	printf '%s: GNU Bash is required for this script\n' "$argv0" >&2
	exit 1
fi

declare argv0
if [[ ! "$0" =~ ^'/' ]]; then
	argv0="$0"
else
	argv0="$(basename -- "$0" && printf x)"
	argv0="${argv0%$'\nx'}"
fi
readonly argv0

#endregion

if [ $# -eq 0 ]; then
	printf '%s: missing argument: <directory>...\n' "$argv0" >&2
	exit
fi

function sort() {
	(
		if [ -n "${LC_ALL-}" ]; then
			export LC_MESSAGES="$LC_ALL"
		fi

		unset -v LC_ALL

		export LC_COLLATE='POSIX' LC_CTYPE='POSIX' LC_NUMERIC='POSIX'

		command sort "$@"
	)
}

function write_shasum_dir_data() {
	local dir_path
	dir_path="$1"
	readonly dir_path

	local -a child_dir_paths
	mapfile -d '' -t child_dir_paths < <(find -P "$dir_path" -mindepth 1 -maxdepth 1 -type d -print0 | sort --zero-terminated)
	readonly child_dir_paths

	local -a child_file_paths
	mapfile -d '' -t child_file_paths < <(find -P "$dir_path" -mindepth 1 -maxdepth 1 -type f -print0 | sort --zero-terminated)
	readonly child_file_paths

	local -a child_symlink_paths
	mapfile -d '' -t child_symlink_paths < <(find -P "$dir_path" -mindepth 1 -maxdepth 1 -type l -print0 | sort --zero-terminated)
	readonly child_symlink_paths

	local -a other_child_entry_paths
	mapfile -d '' -t other_child_entry_paths < <(find -P "$dir_path" -mindepth 1 -maxdepth 1 -not \( -type d -or -type f -or -type l \) -print0 | sort --zero-terminated)
	readonly other_child_entry_paths

	local child_dir_path child_dir_name
	for child_dir_path in "${child_dir_paths[@]}"; do
		child_dir_name="$(basename -- "$child_dir_path" && printf x)"
		child_dir_name="${child_dir_name%$'\nx'}"

		printf -- 'dir:%s\0' "$child_dir_name"

		printf 'entries:'
		write_shasum_dir_data "$child_dir_path"
		printf '\0'
	done
	unset -v child_dir_name child_dir_path

	local child_file_path child_file_name
	for child_file_path in "${child_file_paths[@]}"; do
		child_file_name="$(basename -- "$child_file_path" && printf x)"
		child_file_name="${child_file_name%$'\nx'}"

		printf -- 'file:%s\0' "$child_file_name"

		printf 'contents:'
		cat -- "$child_file_path"
		printf '\0'
	done
	unset -v child_file_name child_file_path

	local child_symlink_path child_symlink_name
	for child_symlink_path in "${child_symlink_paths[@]}"; do
		child_symlink_name="$(basename -- "$child_symlink_path" && printf x)"
		child_symlink_name="${child_symlink_name%$'\nx'}"

		printf -- 'symlink:%s\0' "$child_symlink_name"

		printf 'target:'
		readlink --no-newline -- "$child_symlink_path"
		printf '\0'
	done
	unset -v child_symlink_name child_symlink_path

	local other_child_entry_path other_child_entry_name
	for other_child_entry_path in "${other_child_entry_paths[@]}"; do
		other_child_entry_name="$(basename -- "$other_child_entry_path" && printf x)"
		other_child_entry_name="${other_child_entry_name%$'\nx'}"

		printf -- 'unknown:%s\0' "$other_child_entry_name"
	done
	unset -v other_child_entry_name other_child_entry_path
}

function shasum_dir() {
	local dir_path
	dir_path="$1"
	readonly dir_path

	local hash
	hash="$(write_shasum_dir_data "$dir_path" | sha1sum | cut -d ' ' -f 1)"
	hash="${hash%$'\n'}"
	readonly hash

	printf '%s %s\n' "$hash" "$dir_path"
}

declare dir_path
for dir_path in "$@"; do
	shasum_dir "$dir_path"
done
unset -v dir_path
