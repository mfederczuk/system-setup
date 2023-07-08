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

direction='right'
should_write_to_xclipboard=false

for arg in "$@"; do
	case "$arg" in
		('--left')
			direction='left'
			;;
		('--xcopy')
			should_write_to_xclipboard=true
			;;
		(*)
			{
				printf '%s: %s: invalid argument\n' "$argv0" "$arg"
				printf 'usage: %s [--left] [--xcopy]\n' "$argv0"
			} >&2
			exit 2
			;;
	esac
done

readonly should_write_to_xclipboard direction

#endregion

if $should_write_to_xclipboard && ! command -v xclip > '/dev/null'; then
	printf '%s: xclip: program missing\n' "$argv0" >&2
	exit 27
fi

#region determining zoop

case "$direction" in
	('right')
		zoop='👉😎👉'
		;;
	('left')
		zoop='👈😎👈'
		;;
esac

readonly zoop

#endregion

#region writing

if $should_write_to_xclipboard; then
	printf '%s' "$zoop" | xclip -selection clipboard -i
	exit
fi

if [ -t 1 ]; then
	printf '%s\n' "$zoop"
else
	printf '%s' "$zoop"
fi

#endregion
