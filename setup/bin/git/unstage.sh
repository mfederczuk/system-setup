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
	# when executing script through git - i.e.: `git <command>`

	argv0="$(basename -- "$0" && printf x)"
	argv0="${argv0%"$(printf '\nx')"}"
	argv0="git ${argv0#"git-"}"
else
	# when executing script directly

	if [ "${0#/}" = "$0" ]; then
		argv0="$0"
	else
		argv0="$(basename -- "$0" && printf x)"
		argv0="${argv0%"$(printf '\nx')"}"
	fi
fi
readonly argv0

#endregion

#region patch option

patch=false

if [ $# -ge 1 ] &&
   { [ "$1" = '-p' ] || [ "$1" = '--patch' ]; }; then

	patch=true
	shift 1
fi

readonly patch


patch_opt=''

if $patch; then
	patch_opt='--patch'
fi

readonly patch_opt

#endregion

if [ $# -ne 0 ]; then
	git restore $patch_opt --staged -- "$@"
	exit
fi

#region unstage all

#region prompting

if ! $patch; then
	printf 'Unstage all? [Y/n] ' >&2

	read -r ans

	case "$ans" in
		(['Yy']|'')
			# continue
			;;
		(*)
			printf 'Aborted.\n' >&2
			exit 32
			;;
	esac

	unset -v ans
fi

#endregion

toplevel_pathname="$(git rev-parse --path-format=relative --show-toplevel)"
readonly toplevel_pathname

git restore $patch_opt --staged -- "$toplevel_pathname"

#endregion
