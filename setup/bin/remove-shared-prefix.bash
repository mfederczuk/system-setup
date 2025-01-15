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

if ! command -v determine-shared-prefix > '/dev/null'; then
	printf '%s: determine-shared-prefix: program missing\n' "$argv0" >&2
	exit 27
fi

#region normalizing source pathnames

declare -a source_pathnames
source_pathnames=()

function normalize_pathname() {
	local input_pathname || return
	input_pathname="$1" || return
	readonly input_pathname || return

	# if a pathname starts with exactly two consecutive slashes, pathname resolution is implementation-defined so we
	# don't normalize the pathname
	if [[ "$input_pathname" =~ ^'//'([^'/']|$) ]]; then
		printf '%s' "$input_pathname"
		return
	fi

	#region normalizing the pathname

	local normalized_pathname || return
	normalized_pathname="$input_pathname" || return

	while [[ "$normalized_pathname" =~ '//' ]]; do
		normalized_pathname="${normalized_pathname//'//'/'/'}" || return
	done

	# shellcheck disable=2076
	while [[ "$normalized_pathname" =~ '/./' ]]; do
		normalized_pathname="${normalized_pathname//'/./'/'/'}" || return
	done

	if [[ "$normalized_pathname" =~ ^'./'(.+)$ ]]; then
		normalized_pathname="${BASH_REMATCH[1]}" || return
	fi

	if [[ "$normalized_pathname" =~ ^(.*'/')'.'$ ]]; then
		normalized_pathname="${BASH_REMATCH[1]}" || return
	fi

	readonly normalized_pathname || return

	#endregion

	printf '%s' "$normalized_pathname"
}

declare source_pathname
for source_pathname in "$@"; do
	source_pathname="$(normalize_pathname "$source_pathname" && printf x)"
	source_pathname="${source_pathname%x}"

	source_pathnames+=("$source_pathname")
done
unset -v source_pathname

unset -f normalize_pathname

readonly source_pathnames

#endregion

declare shared_prefix
shared_prefix="$(determine-shared-prefix "${source_pathnames[@]}" && printf x)"
shared_prefix="${shared_prefix%x}"
readonly shared_prefix

declare source_pathname
for source_pathname in "$@"; do
	declare target_pathname
	target_pathname="${source_pathname#"$shared_prefix"}"

	if [ ! -e "$source_pathname" ]; then
		printf '%s: %s: no such file or directory\n' "$argv0" "$source_pathname" >&2
		exit 24
	fi

	if [ -e "$target_pathname" ]; then
		printf '%s: %s: file or directory already exists\n' "$argv0" "$target_pathname" >&2
		exit 25
	fi

	unset -v target_pathname
done
unset -v source_pathname

declare source_pathname
for source_pathname in "$@"; do
	declare target_pathname
	target_pathname="${source_pathname#"$shared_prefix"}"

	mv -i -- "$source_pathname" "$target_pathname"
	printf "Renamed '%s' -> '%s'\\n" "$source_pathname" "$target_pathname" >&2

	unset -v target_pathname
done
