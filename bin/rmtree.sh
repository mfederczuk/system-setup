#!/bin/sh
# -*- sh -*-
# vim: syntax=sh
# code: language=shellscript

# Copyright (c) 2024 Michael Federczuk
# SPDX-License-Identifier: MPL-2.0 AND Apache-2.0

#region preamble

case "$-" in
	(*'i'*)
		\command printf 'script was called interactively\n' >&2
		return 124
		;;
esac

set -o errexit
set -o nounset

# enabling POSIX-compliant behavior for GNU programs
export POSIXLY_CORRECT=yes POSIX_ME_HARDER=yes

if [ "${0#/}" = "$0" ]; then
	argv0="$0"
else
	argv0="$(basename -- "$0" && printf x)"
	argv0="${argv0%"$(printf '\nx')"}"
fi
readonly argv0

#endregion

if [ "${1-}" = '--help' ]; then
	printf 'usage: %s <directory>...\n' "$argv0"
	printf '    Remove all <directory> arguments recursively if - and only if - the hierarchies contains only (empty) directories.\n'
	printf '\n'
	printf 'GitHub Repository: <https://github.com/mfederczuk/system-setup>\n'
	exit
fi

sparse=false
if [ "${1-}" = '--sparse' ]; then
	sparse=true
	shift 1
fi
readonly sparse

if [ $# -eq 0 ]; then
	{
		printf '%s: missing arguments: <directory>...\n' "$argv0"
		printf 'usage: %s <directory>...\n' "$argv0"
	} >&2
	exit 3
fi

normalize_pathname() {
	if printf '%s' "$1" | grep -Eq '^//([^/]|$)'; then
		printf '%s' "$1"
		return
	fi

	set -- "$(printf '%s' "$1" | tr -s '/')" || return

	while printf '%s' "$1" | grep -Fq '/./'; do
		set -- "$(printf '%s' "$1" | sed -e s%'/\./'%'/'%g)" || return
	done

	set -- "$(printf '%s' "$1" | sed -e s%'^\./\(..*\)$'%'\1'%)" || return

	set -- "$(printf '%s' "$1" | sed -e s%'^\(.*/\)\.$'%'\1'%)" || return

	printf '%s' "$1"
}

#region pre-remove checks

if [ $# -eq 1 ]; then
	if [ -z "$1" ]; then
		printf '%s: argument must not be empty\n' "$argv0" >&2
		exit 9
	fi
else
	i=0

	for arg in "$@"; do
		i=$((i + 1))

		if [ -n "$arg" ]; then
			continue
		fi

		printf '%s: argument %d: must not be empty\n' "$argv0" $i >&2
		exit 9
	done

	unset -v i
fi

check_empty_tree_recursively() {
	if [ ! -r "$1" ]; then
		printf '%s: %s: permission denied: read permission missing\n' "$argv0" "$1" >&2
		return 77
	fi

	for __check_empty_tree_recursively__entry_path in "$1/"* "$1/."*; do
		set -- "$1" "$__check_empty_tree_recursively__entry_path"
		unset -v __check_empty_tree_recursively__entry_path

		case "$2" in
			("$1/."|"$1/..")
				continue
				;;
			("$1/*"|"$1/.*")
				if [ ! -e "$2" ]; then
					continue
				fi
				;;
		esac

		if [ ! -d "$2" ]; then
			if $sparse; then
				return
			fi

			printf '%s: %s: directory not empty\n' "$argv0" "$1" >&2
			return 48
		fi

		check_empty_tree_recursively "$2"
	done

	set -- "$1" "$(dirname -- "$1" && printf x)"
	set -- "$1" "${2%"$(printf '\nx')"}"

	if [ ! -w "$2" ]; then
		printf '%s: %s: permission denied: write permission missing\n' "$argv0" "$2" >&2
		return 77
	fi
}

for path in "$@"; do
	path="$(normalize_pathname "$path" && printf x)"
	path="${path%x}"

	if [ ! -e "$path" ]; then
		printf '%s: %s: no such directory\n' "$argv0" "$path" >&2
		exit 24
	fi

	if [ ! -d "$path" ]; then
		printf '%s: %s: not a directory\n' "$argv0" "$path" >&2
		exit 26
	fi

	check_empty_tree_recursively "$path"
done
unset -v path

#endregion

#region main

quote_pathname() {
	if printf '%s' "$1" | grep -Fqv \'; then
		printf "'%s'" "$1"
		return
	fi

	set -- "$(printf '%s' "$1" | sed -e s/\\/\\\\/g)"
	set -- "$(printf '%s' "$1" | sed -e s/\"/\\\"/g)"
	printf '"%s"' "$1"
}

remove_empty_tree_recursively() {
	if [ ! -r "$1" ]; then
		printf '%s: %s: permission denied: read permission missing\n' "$argv0" "$1" >&2
		return 77
	fi

	for __remove_empty_tree_recursively__entry_path in "$1/"* "$1/."*; do
		set -- "$1" "$(normalize_pathname "$__remove_empty_tree_recursively__entry_path" && printf x)"
		set -- "$1" "${2%x}"
		unset -v __remove_empty_tree_recursively__entry_path

		case "$2" in
			("$1/."|"$1/..")
				continue
				;;
			("$1/*"|"$1/.*")
				if [ ! -e "$2" ]; then
					continue
				fi
				;;
		esac

		if [ ! -d "$2" ]; then
			if $sparse; then
				set -- "$1" "$(quote_pathname "$2")"
				printf 'Skipped non-empty directory %s (--sparse)\n' "$2" >&2
				return 32
			fi

			printf '%s: %s: directory not empty\n' "$argv0" "$1" >&2
			return 48
		fi

		remove_empty_tree_recursively "$2"

		set -- "$1" "$(quote_pathname "$2")"
		printf 'Removed empty directory %s\n' "$2" >&2
	done

	set -- "$1" "$(dirname -- "$1" && printf x)"
	set -- "$1" "${2%"$(printf '\nx')"}"

	if [ ! -w "$2" ]; then
		printf '%s: %s: permission denied: write permission missing\n' "$argv0" "$2" >&2
		return 77
	fi

	rmdir -- "$1"
}

for dir_path in "$@"; do
	dir_path="$(normalize_pathname "$dir_path" && printf x)"
	dir_path="${dir_path%x}"

	if [ ! -e "$dir_path" ]; then
		continue
	fi

	if [ ! -d "$dir_path" ]; then
		printf '%s: %s: not a directory\n' "$argv0" "$dir_path" >&2
		exit 26
	fi

	remove_empty_tree_recursively "$dir_path"
done

#endregion
