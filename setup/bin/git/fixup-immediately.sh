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

# asserts that we're in a repository and at least one commit exists
git --no-pager show 1> '/dev/null'

if [ -n "${GIT_EXEC_PATH-}" ]; then
	# when executing the script through git - i.e.: `git <command>`

	argv0="$(basename -- "$0" && printf x)"
	argv0="${argv0%"$(printf '\nx')"}"
	argv0="git ${argv0#"git-"}"
else
	# when executing the script directly - i.e.: `git-<command>`

	if [ "${0#/}" = "$0" ]; then
		argv0="$0"
	else
		argv0="$(basename -- "$0" && printf x)"
		argv0="${argv0%"$(printf '\nx')"}"
	fi
fi
readonly argv0

#endregion

#region args

print_usage() {
	printf 'usage: %s <commit>\n' "$argv0"
}

case $# in
	(0)
		{
			printf '%s: missing argument: <commit>\n' "$argv0" >&2
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

		commit="$1"
		;;
	(*)
		{
			printf '%s: too many arguments: %i\n' "$argv0" $(($# - 1)) >&2
			print_usage
		}
		exit 4
		;;
esac

unset -f print_usage

readonly commit

#endregion

git --no-pager commit --fixup="$commit"

git -c core.editor=true rebase --interactive --autosquash --autostash -- "$commit^"
