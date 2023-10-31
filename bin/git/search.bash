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

# asserts that we're in a repository and at least one commit exists
git --no-pager show 1> '/dev/null'

declare argv0
if [ -n "${GIT_EXEC_PATH-}" ]; then
	# when executing the script through git - i.e.: `git <command>`

	argv0="$(basename -- "$0" && printf x)"
	argv0="${argv0%$'\nx'}"
	argv0="git ${argv0#"git-"}"
else
	# when executing the script directly - i.e.: `git-<command>`

	if [[ ! "$0" =~ ^'/' ]]; then
		argv0="$0"
	else
		argv0="$(basename -- "$0" && printf x)"
		argv0="${argv0%$'\nx'}"
	fi
fi
readonly argv0

#endregion

#region args

function print_usage() {
	printf 'usage: %s <regex>\n' "$argv0"
}

declare regex_search_pattern

case $# in
	(0)
		{
			printf '%s: missing argument: <regex>\n' "$argv0"
			print_usage
		} >&2
		exit 3
		;;
	(1)
		if [ -z "$1" ]; then
			{
				printf '%s: argument must not be empty\n' "$argv0"
				print_usage
			} >&2
			exit 9
		fi

		regex_search_pattern="$1"
		;;
	(*)
		{
			printf '%s: too many arguments: %d\n' "$argv0" $#
			print_usage
		} >&2
		exit 4
		;;
esac

readonly regex_search_pattern

unset -f print_usage

#endregion

#region collecting untracked paths

declare was_prompted
was_prompted=false

declare -a untracked_pathnames
untracked_pathnames=()

declare status pathname
while read -r -d '' -u 3; do
	status="${REPLY:0:2}"
	pathname="${REPLY:3}"

	if [ "$status" != '??' ] || [ ! -f "$pathname" ]; then
		continue
	fi

	if ((${#untracked_pathnames[@]} == 0)); then
		printf 'The working tree contains untracked files. Include them as well? [Y/n] ' >&2
		was_prompted=true

		read -r ans

		case "$ans" in
			(['Yy']*|'')
				unset -v ans
				;;
			(*)
				unset -v ans
				break
				;;
		esac
	fi

	untracked_pathnames+=("$pathname")
done 3< <(git -c status.renames=false status --porcelain=v1 --untracked-files=all --ignored=no -z --no-renames)
unset -v pathname status

readonly untracked_pathnames

readonly was_prompted

#endregion

#region collecting tree paths

declare -a pathnames
pathnames=()

declare pathname
while read -r -d ''; do
	pathname="$REPLY"

	if [ ! -f "$pathname" ]; then
		continue
	fi

	pathnames+=("$pathname")
done < <(git --no-pager ls-tree -r -z --name-only --full-tree HEAD)
unset -v pathname

pathnames+=("${untracked_pathnames[@]}")

readonly pathnames

#endregion

if ((${#pathnames[@]} == 0)); then
	printf 'No paths to search.\n' >&2
	exit
fi

#region searching pathnames

declare -a found_pathnames_via_pathname
found_pathnames_via_pathname=()

declare pathname
for pathname in "${pathnames[@]}"; do
	if ! { printf '%s' "$pathname" | grep -Eq -- "$regex_search_pattern"; }; then
		continue
	fi

	found_pathnames_via_pathname+=("$pathname")
done
unset -v pathname

readonly found_pathnames_via_pathname

#endregion

#region searching contents

declare -a found_pathnames_via_contents
found_pathnames_via_contents=()

declare pathname
for pathname in "${pathnames[@]}"; do
	if ! grep -Eq -- "$regex_search_pattern" "$pathname"; then
		continue
	fi

	found_pathnames_via_contents+=("$pathname")
done
unset -v pathname

readonly found_pathnames_via_contents

#endregion

#region terminal effects

function is_stdin_effects_supported() {
	if [ -n "${NO_COLOR-}" ] || [ ! -t 1 ] || ! command -v tput > '/dev/null'; then
		return 32;
	fi

	case "${TERM-}" in
		('xterm-color'|*'-256color'|'xterm-kitty')
			return 0
			;;
	esac

	if tput 'setaf' '1' >&'/dev/null'; then
		return 0;
	else
		return 32;
	fi
}

declare fx_reset fx_bold fx_red fx_green fx_blue
if is_stdin_effects_supported; then
	fx_reset="$(tput sgr0)"
	fx_bold="$(tput bold)"
	fx_red="$(tput setaf 1)"
	fx_green="$(tput setaf 2)"
	fx_blue="$(tput setaf 4)"
else
	fx_reset=''
	fx_bold=''
	fx_red=''
	fx_green=''
	fx_blue=''
fi
readonly fx_blue fx_green fx_red fx_bold fx_reset

unset -f is_stdin_effects_supported

#endregion

#region printing

if $was_prompted; then
	printf '\n' >&2
fi

if [ ${#found_pathnames_via_pathname[@]} = 0 ]; then
	printf '%sNo matches by pathname.%s\n' "${fx_red}${fx_bold}" "$fx_reset"
else
	printf '%sMatches by pathname:%s\n' "${fx_green}${fx_bold}" "$fx_reset"

	declare pathname
	for pathname in "${found_pathnames_via_pathname[@]}"; do
		printf '\t%s%s%s\n' "$fx_green" "$pathname" "$fx_reset"
	done
	unset -v pathname
fi

if [ ${#found_pathnames_via_contents[@]} = 0 ]; then
	printf '\n%sNo matches by content.%s\n' "${fx_red}${fx_bold}" "$fx_reset"
else
	printf '\n%sMatches by content:%s\n' "${fx_blue}${fx_bold}" "$fx_reset"

	declare pathname
	for pathname in "${found_pathnames_via_contents[@]}"; do
		printf '\t%s%s%s\n' "$fx_blue" "$pathname" "$fx_reset"
	done
	unset -v pathname
fi

#endregion
