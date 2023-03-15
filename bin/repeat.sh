#!/bin/sh
# -*- sh -*-
# vim: syntax=sh
# code: language=shellscript

# Copyright (c) 2023 Michael Federczuk
# SPDX-License-Identifier: MPL-2.0 AND Apache-2.0

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

#region args

print_usage() {
	printf 'usage: %s <count> <command> [<args>...]\n' "$argv0" >&2
}

case $# in
	(0)
		printf '%s: missing arguments: <count> <command> [<args>...]\n' "$argv0" >&2
		print_usage
		exit 3
		;;
	(1)
		printf '%s: missing arguments: <command> [<args>...]\n' "$argv0" >&2
		print_usage
		exit 3
		;;
	(*)
		if [ -z "$1" ]; then
			printf '%s: argument 1: must not be empty\n' "$argv0" >&2
			print_usage
			exit 9
		fi

		if [ -z "$2" ]; then
			printf '%s: argument 2: must not be empty\n' "$argv0" >&2
			print_usage
			exit 9
		fi

		count="$1"

		ln_count="$(printf '%s' "$count" | wc -l)"
		if [ "$ln_count" -gt 0 ] || ! { printf '%s' "$count" | grep -Eq '^[+-]?[0-9]+$'; }; then
			printf '%s: %s: not an integer\n' "$argv0" "$count" >&2
			print_usage
			exit 10
		fi
		unset -v ln_count

		count=$((count)) # this shuts up ShellCheck for quoting $count

		if [ $count -lt 0 ]; then
			printf '%s: %i: out of range: < 0' "$argv0" $count >&2
			print_usage
			exit 11
		fi
		;;
esac

unset -f print_usage

readonly count

shift 1

#endregion

i=0

while [ $i -lt $count ]; do
	REPEAT_NR=$((i + 1)) "$@"
	i=$((i + 1))
done
