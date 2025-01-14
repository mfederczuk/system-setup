#!/bin/sh
# vim: syntax=sh
# code: language=shellscript

# SPDX-License-Identifier: CC0-1.0

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

if [ $# -gt 0 ]; then
	printf '%s: too many arguments: %i\n' "$argv0" $# >&2
	exit 4
fi


lenny='( ͡° ͜ʖ ͡°)'
readonly lenny

if [ -t 1 ]; then
	printf '%s\n' "$lenny"
else
	printf '%s' "$lenny"
fi
