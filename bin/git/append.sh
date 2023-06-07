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

#region main

#region extracting marker

HEAD_commit_subject="$(git --no-pager show --no-patch --pretty='format:%s' HEAD)"
readonly HEAD_commit_subject


marker=''

if printf '%s' "$HEAD_commit_subject" | grep -Eiq '^(!)?(tmp|wip)(!)?([^[:alnum:]_]|$)'; then
	marker='wip'
elif printf '%s' "$HEAD_commit_subject" | grep -Eiq '^(!)?todo(!)?([^[:alnum:]_]|$)'; then
	marker='todo'
fi

readonly marker

#endregion

reset_date=false
should_ask_for_message_edit=false

case "$marker" in
	('wip')
		reset_date=true
		should_ask_for_message_edit=true
		;;
	('todo')
		should_ask_for_message_edit=true
		;;
esac

readonly reset_date should_ask_for_message_edit


git_commit_date_option=''

if $reset_date; then
	if [ -t 2 ]; then
		printf 'The date will be reset. Continue? [Y/n] ' >&2

		read -r ans

		case "$ans" in
			(['yY']|'')
				# continue
				;;
			(*)
				printf 'Aborted.\n' >&2
				exit 32
				;;
		esac

		unset -v ans
	fi

	git_commit_date_option='--date=now'
fi

readonly git_commit_date_option


git_commit_edit_option='--no-edit'

if [ -t 2 ] && $should_ask_for_message_edit; then
	git_status="$(git --no-pager status --porcelain=v1)"

	if [ -z "$git_status" ]; then
		printf 'No more unstaged changes. Edit the commit message? [Y/n] ' >&2

		read -r ans

		case "$ans" in
			(['yY']|'') should_edit_message=true  ;;
			(*)         should_edit_message=false ;;
		esac

		if $should_edit_message; then
			git_commit_edit_option='--edit'
		fi

		unset -v should_edit_message ans
	fi

	unset -v git_status
fi

readonly git_commit_edit_option


git commit --amend "$git_commit_edit_option" $git_commit_date_option "$@"

#endregion
