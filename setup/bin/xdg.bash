#!/bin/bash
# -*- sh -*-
# vim: syntax=sh
# code: language=shellscript

# Copyright (c) 2023 Michael Federczuk
# SPDX-License-Identifier: MPL-2.0 AND Apache-2.0

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

# enabling POSIX-compliant behavior for GNU programs
export POSIXLY_CORRECT=yes POSIX_ME_HARDER=yes

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

#region checking environment

if ! command -v xdg-open > '/dev/null'; then
	printf '%s: xdg-open: program missing\n' "$argv0" >&2
	exit 27
fi

#endregion

#region handling arguments

if (($# == 0)); then
	{
		printf '%s: missing arguments: <file | URL>...\n' "$argv0"
		printf 'usage: %s <file | URL>...\n' "$argv0"
	} >&2
	exit 3
fi

#endregion

#region collecting options

declare -a options
options=()

declare arg
for arg in "$@"; do
	if [[ ! "$arg" =~ ^'-' ]]; then
		continue
	fi

	options+=("$arg")
done
unset -v arg

readonly options

#endregion

if ((${#options[@]} > 0)); then
	xdg-open "${options[@]}"
	exit
fi

for arg in "$@"; do
	xdg-open "$arg"
done
