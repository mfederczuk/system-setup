#!/bin/sh
# -*- sh -*-
# vim: syntax=sh
# code: language=shellscript

# Copyright (c) 2023 Michael Federczuk
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

# asserts that we're in a repository and at least one commit exists
git --no-pager show 1> '/dev/null'

if [ -n "${GIT_EXEC_PATH-}" ]; then
	# when executing the script through git - i.e.: `git <command>`

	argv0="$(basename -- "$0" && printf x)"
	argv0="${argv0%"$(printf '\nx')"}"
	argv0="git ${argv0#"git-"}"
else
	# when executing the script directly - i.e.: `git-<command>`

	if [ "${0#/}" = "$0" ]; then
		argv0="$0"
	else
		argv0="$(basename -- "$0" && printf x)"
		argv0="${argv0%"$(printf '\nx')"}"
	fi
fi
readonly argv0

#endregion

#region args

if [ $# -eq 0 ]; then
	printf '%s: missing arguments: <file>...\n' "$argv0" >&2
	exit 3
fi

#endregion

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

#region main

for pathname in "$@"; do
	pathname="$(normalize_pathname "$pathname")"

	if [ ! -e "$pathname" ]; then
		printf '%s: %s: no such file or directory\n' "$argv0" "$pathname" >&2
		exit 24
	fi


	basename="$(basename -- "$pathname" && printf x)"
	basename="${basename%"$(printf '\nx')"}"

	basename_newline_count=$(printf '%s' "$basename" | wc -l)

	if [ "$basename_newline_count" -gt 0 ]; then
		printf '%s: %s: filename contains newline characters\n' "$argv0" "$pathname" >&2
		exit 13
	fi

	unset -v basename_newline_count basename
done; unset -v pathname


is_at_least_one_strange_basename=false

for src_pathname in "$@"; do
	src_pathname="$(normalize_pathname "$src_pathname")"

	if [ ! -e "$src_pathname" ]; then
		printf '%s: %s: no such file or directory\n' "$argv0" "$src_pathname" >&2
		exit 24
	fi

	src_basename="$(basename -- "$src_pathname" && printf x)"
	src_basename="${src_basename%"$(printf '\nx')"}"

	case "$src_basename" in
		(*'.ignore'|*'.ignore.'*)
			printf "Filename '%s' already matches ignore pattern. Not renaming it.\\n" "$src_basename" >&2
			continue
			;;
	esac

	if ! { printf '%s' "$src_basename" | grep -Eq '^\.?[^.]+(\.[A-Za-z0-9_-]+)*$'; }; then
		is_at_least_one_strange_basename=true
		printf '%s: %s: strange filename. not renaming it\n' "$argv0" "$src_pathname" >&2
		continue
	fi

	src_suffix="$(printf '%s' "$src_basename" | sed -ne s/'^\.*[^.]\{1,\}\(\..*\)$'/'\1'/p)"

	target_basename="${src_basename%"$src_suffix"}.ignore$src_suffix"

	parent_dir_pathname="$(dirname -- "$src_pathname" && printf x)"
	parent_dir_pathname="${parent_dir_pathname%"$(printf '\nx')"}"

	target_pathname="$parent_dir_pathname/$target_basename"
	target_pathname="$(normalize_pathname "$target_pathname")"

	if [ -e "$target_pathname" ]; then
		printf '%s: %s: file or directory already exists\n' "$argv0" "$target_pathname" >&2
		exit 25
	fi

	mv -i -- "$src_pathname" "$target_pathname"
	printf "Renamed '%s' to '%s'\\n" "$src_pathname" "$target_pathname" >&2
done

readonly is_at_least_one_strange_basename

if $is_at_least_one_strange_basename; then
	exit 48
fi

#endregion
