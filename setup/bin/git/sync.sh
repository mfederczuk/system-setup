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

#region args

print_usage() {
	printf 'usage: %s [<remote>]' "$argv0" >&2
}

case $# in
	(0)
		remote_spec='all'
		;;
	(1)
		if [ -z "$1" ]; then
			printf '%s: argument must not be empty\n' "$argv0" >&2
			print_usage
			exit 9
		fi

		remote_spec="one:$1"
		;;
	(*)
		printf '%s: too many arguments: %i\n' "$argv0" $(($# - 1)) >&2
		print_usage
		exit 4
		;;
esac

readonly remote_spec

unset -f print_usage

#endregion

#region main

exists_git_command() {
	_exists_git_command_command_name="$1" || return

	#region checking aliases

	if git --no-pager config --get --system alias."$_exists_git_command_command_name" > '/dev/null'; then
		unset -v _exists_git_command_command_name
		return 0
	fi

	if git --no-pager config --get --global alias."$_exists_git_command_command_name" > '/dev/null'; then
		unset -v _exists_git_command_command_name
		return 0
	fi

	#endregion

	# checking custom commands
	if command -v "git-$_exists_git_command_command_name" > '/dev/null'; then
		unset -v _exists_git_command_command_name
		return 0
	fi

	# checking official commands
	if git --no-pager help "$_exists_git_command_command_name" 1> '/dev/null' 2> '/dev/null' < '/dev/null'; then
		unset -v _exists_git_command_command_name
		return 0
	fi

	unset -v _exists_git_command_command_name

	return 32
}

case "$remote_spec" in
	('one:'?*)
		remote="${remote_spec#"one:"}"

		git fetch -- "$remote"

		printf '\n' >&2

		git remote prune -- "$remote"

		unset -v remote
		;;
	('all')
		git fetch --all

		printf '\n' >&2

		git --no-pager remote |
			while read -r remote; do
				git remote prune -- "$remote"
				unset -v remote
			done
		;;
	(*)
		printf '%s: emergency stop: value of variable remote_spec ("%s") is invalid' "$argv0" "$remote_spec" >&2
		exit 123
		;;
esac

if exists_git_command prune-local-branches; then
	printf '\n' >&2

	git prune-local-branches
fi

#endregion
