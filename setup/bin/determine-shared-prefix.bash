#!/bin/bash
# -*- sh -*-
# vim: syntax=sh
# code: language=shellscript

# Copyright (c) 2024 Michael Federczuk
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

if [ $# -eq 0 ]; then
	exit
fi

function starts_with() {
	test "${1#"$2"}" != "$1"
}

declare first_arg
first_arg="$1"
readonly first_arg

declare -i found_shared_prefix_length
found_shared_prefix_length=0

while true; do
	declare is_shared_prefix
	is_shared_prefix=true

	declare -i potential_new_shared_prefix_length
	potential_new_shared_prefix_length=$((found_shared_prefix_length + 1))

	declare potential_new_shared_prefix
	potential_new_shared_prefix="${first_arg:0:potential_new_shared_prefix_length}"

	declare arg
	for arg in "$@"; do
		if [ ${#arg} -lt $potential_new_shared_prefix_length ] ||
			! starts_with "$arg" "$potential_new_shared_prefix"; then

			is_shared_prefix=false
			break
		fi
	done
	unset -v arg

	unset -v potential_new_shared_prefix

	if $is_shared_prefix; then
		found_shared_prefix_length=$((potential_new_shared_prefix_length))
	fi

	unset -v potential_new_shared_prefix_length

	if ! $is_shared_prefix; then
		unset -v is_shared_prefix
		break
	fi
	unset -v is_shared_prefix
done

readonly found_shared_prefix_length

printf '%s' "${first_arg:0:found_shared_prefix_length}"
if [ -t 1 ]; then
	printf '\n'
fi
