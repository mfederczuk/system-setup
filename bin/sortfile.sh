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

if [ "${0#/}" = "$0" ]; then
	argv0="$0"
else
	argv0="$(basename -- "$0" && printf x)"
	argv0="${argv0%"$(printf '\nx')"}"
fi
readonly argv0

#endregion

#region handling arguments

if [ $# -eq 0 ]; then
	{
		printf '%s: missing arguments: <file>...\n' "$argv0"
		printf 'usage: %s <file>...\n' "$argv0"
	} >&2
	return 3
fi

#endregion

#region checking files

for pathname in "$@"; do
	if [ ! -e "$pathname" ]; then
		printf '%s: %s: no such file\n' "$argv0" "$pathname" >&2
		exit 24
	fi

	if [ ! -f "$pathname" ]; then
		if [ -d "$pathname" ]; then
			what='file'
		else
			what='regular file'
		fi
		readonly what

		printf '%s: %s: not a %s\n' "$argv0" "$pathname" "$what" >&2
		return 26
	fi

	if [ ! -r "$pathname" ]; then
		printf '%s: %s: permission denied: read permission missing\n' "$argv0" "$pathname" >&2
		return 77
	fi

	if [ ! -w "$pathname" ]; then
		printf '%s: %s: permission denied: write permission missing\n' "$argv0" "$pathname" >&2
		return 77
	fi
done

#endregion

#region sorting

for pathname in "$@"; do
	# POSIX defines that using the same file as input and output is ok
	sort -o "$pathname" -- "$pathname" || return
done

#endregion
