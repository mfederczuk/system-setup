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

if [ $# -gt 0 ]; then
	printf '%s: too many arguments: %i\n' "$argv0" $# >&2
	exit 4
fi

#endregion

#region checking for clean working tree

tmp="$(git status --porcelain=v1 | wc -c)"

if [ "$tmp" -eq 0 ]; then
	printf 'Nothing to purge: working tree is clean.\n' >&2
	exit 0
fi

unset -v tmp

#endregion

#region user prompting

{
	printf 'Purge all changes?\n'
	printf 'This operation will remove ALL of your uncommitted changes and will leave the index and working tree in a clean state.\n'
	printf 'Continue? [y/N] '
} >&2

read -r ans

case "$ans" in
	(['yY']*)
		# continue
		;;
	(*)
		printf 'Aborted.\n' >&2
		exit 32
		;;
esac

unset -v ans

#endregion

#region safety commit

git add --all

tree_hash="$(git write-tree)"
commit_hash="$(git commit-tree -p HEAD -m 'Safety commit before the purge' "$tree_hash")"
readonly commit_hash
unset -v tree_hash

printf 'Safety commit with all purged changes: %s (unreachable)\n' "$commit_hash" >&2

#endregion

git restore --source=HEAD --staged --worktree # removes staged & unstaged changes

git clean -d --force # removes untracked files
