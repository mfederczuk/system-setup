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

#region args

print_usage() {
	printf 'usage: %s <max_retry_count> <command> [<args>...]\n' "$argv0" >&2
}

case $# in
	(0)
		printf '%s: missing arguments: <max_retry_count> <command> [<args>...]\n' "$argv0" >&2
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

		max_retry_count="$1"

		ln_count="$(printf '%s' "$max_retry_count" | wc -l)"
		if [ "$ln_count" -gt 0 ] || ! { printf '%s' "$max_retry_count" | grep -Eq '^[+-]?[0-9]+$'; }; then
			printf '%s: %s: not an integer\n' "$argv0" "$max_retry_count" >&2
			print_usage
			exit 10
		fi
		unset -v ln_count

		max_retry_count=$((max_retry_count)) # this shuts up ShellCheck for quoting $count

		if [ $max_retry_count -lt 0 ]; then
			printf '%s: %i: out of range: < 0' "$argv0" $max_retry_count >&2
			print_usage
			exit 11
		fi
		;;
esac

unset -f print_usage

readonly max_retry_count

shift 1

#endregion

#region main

set +o errexit

RETRY_NR=0 "$@"
exc=$?

if [ $exc -eq 0 ]; then
	exit
fi

retry_i=0

while [ $retry_i -lt $max_retry_count ]; do
	RETRY_NR=$((retry_i + 1)) "$@"
	exc=$?

	if [ $exc -eq 0 ]; then
		exit
	fi

	retry_i=$((retry_i + 1))
done

exit $exc

#endregion
