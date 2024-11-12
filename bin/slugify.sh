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

if [ $# -eq 0 ]; then
	printf '%s: missing arguments: <file>...\n' "$argv0" >&2
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

slugify() {
	set -- "$(printf '%s' "$1" |
	          	sed -e s/"'s"/'s'/g |
	          	tr '[:upper:]' '[:lower:]' |
	          	sed -e s/"we're"/'were'/g |
	          	sed -e s/"i'm"/'im'/g |
	          	sed -e s/'&'/'and'/g |
	          	sed -e s/'[^a-z0-9]'/'-'/g |
	          	sed -e s/'-\{2,\}'/'-'/g)" || return

	set -- "${1#-}" || return
	set -- "${1%-}" || return

	printf '%s' "$1"
}

slugify_filename() {
	set -- "$(printf '%s' "$1" | sed -e s/'^\(\.*\)\([^.]\{1,\}\)\(\..*\)\{0,1\}$'/'\1'/)" \
	       "$(printf '%s' "$1" | sed -e s/'^\(\.*\)\([^.]\{1,\}\)\(\..*\)\{0,1\}$'/'\2'/)" \
	       "$(printf '%s' "$1" | sed -e s/'^\(\.*\)\([^.]\{1,\}\)\(\..*\)\{0,1\}$'/'\3'/)" || return

	set -- "$1" "$(slugify "$2")" "$3" || return

	printf '%s%s%s' "$1" "$2" "$3"
}

slugify_basename_of_pathname() {
	set -- "$(normalize_pathname "$1" && printf x)" || return
	set -- "${1%x}" || return

	set -- "$(dirname -- "$1" && printf x)" \
	       "$(basename -- "$1" && printf x)" || return

	set -- "${1%"$(printf '\nx')"}" "${2%"$(printf '\nx')"}" || return

	set -- "$1" "$(slugify_filename "$2")" || return

	set -- "$(normalize_pathname "$1/$2" && printf x)" || return
	set -- "${1%x}" || return

	printf '%s' "$1"
}

for source_pathname in "$@"; do
	source_pathname="$(normalize_pathname "$source_pathname" && printf x)"
	source_pathname="${source_pathname%x}"

	if [ ! -e "$source_pathname" ]; then
		printf '%s: %s: no such file or directory\n' "$argv0" "$source_pathname" >&2
		exit 24
	fi

	target_pathname="$(slugify_basename_of_pathname "$source_pathname" && printf x)"
	target_pathname="${target_pathname%x}"

	if [ -e "$target_pathname" ]; then
		printf '%s: %s: file or directory already exists\n' "$argv0" "$target_pathname" >&2
		exit 25
	fi

	unset -v target_pathname
done; unset -v source_pathname

for source_pathname in "$@"; do
	source_pathname="$(normalize_pathname "$source_pathname" && printf x)"
	source_pathname="${source_pathname%x}"

	target_pathname="$(slugify_basename_of_pathname "$source_pathname" && printf x)"
	target_pathname="${target_pathname%x}"

	mv -i -- "$source_pathname" "$target_pathname"
	printf "Renamed '%s' -> '%s'\\n" "$source_pathname" "$target_pathname" >&2

	unset -v target_pathname
done
