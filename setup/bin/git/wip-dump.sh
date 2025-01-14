#!/bin/sh
# -*- sh -*-
# vim: syntax=sh
# code: language=shellscript

# Copyright (c) 2024 Michael Federczuk
# SPDX-License-Identifier: MPL-2.0 AND Apache-2.0

# <https://github.com/mfederczuk/git-wip-dump/blob/v0.2.0/git-wip-dump>

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

git() {
	command git --no-pager "$@"
}

# asserts that we're in a repository and at least one commit exists
git show 1> '/dev/null'

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

# $1: string
# $2: char index
char_at() {
	printf '%s' "$1" | dd bs=1 count=1 skip="$2" 2> '/dev/null'
}

readonly git_wip_dump_version_major=0
readonly git_wip_dump_version_minor=2
readonly git_wip_dump_version_patch=0
readonly git_wip_dump_version_pre_release=''
git_wip_dump_version() {
	printf '%i.%i.%i' "$git_wip_dump_version_major" "$git_wip_dump_version_minor" "$git_wip_dump_version_patch"

	if [ -n "$git_wip_dump_version_pre_release" ]; then
		printf '%s' "-$git_wip_dump_version_pre_release"
	fi
}

# region args

print_usage() {
	printf 'usage: %s save [--push]\n' "$argv0"
	printf '   or: %s restore\n' "$argv0"
}

print_help() {
	print_usage
	printf '\n'
	printf '    --push                also push the created commit to the tracked upstream\n'
}

print_version_info() {
	printf 'git-wip-dump %s\n' "$(git_wip_dump_version)"
	printf '\n'
	printf 'Copyright (C) 2024 Michael Federczuk\n'
	printf '\n'
	printf '    License MPL-2.0: Mozilla Public License 2.0 <https://www.mozilla.org/en-US/MPL/2.0/>\n'
	printf '            AND\n'
	printf '    License Apache-2.0: Apache License 2.0 <https://www.apache.org/licenses/LICENSE-2.0>\n'
	printf '\n'
	printf 'This is free software: you are free to change and redistribute it.\n'
	printf 'There is NO WARRANTY, to the extent permitted by law.\n'
	printf '\n'
	printf 'Written by Michael Federczuk.\n'
}

subcommand=''
subcommand_set=false

readonly opt_push_unspecified=''
readonly opt_push_yes='yes'
readonly opt_push_no='no'
opt_push="$opt_push_unspecified"

excess_argc=0

invalid_opt=''

process_opts=true

for arg in "$@"; do
	if $process_opts && [ "$arg" = '--' ]; then
		process_opts=false
		continue
	fi

	if $process_opts && printf '%s' "$arg" | grep -Eq '^--'; then
		opt_long_identifier="${arg#--}"

		case "$opt_long_identifier" in
			('help')
				print_help
				exit
				;;
			('version')
				print_version_info
				exit
				;;
			('push')
				opt_push="$opt_push_yes"
				;;
			('no-push')
				opt_push="$opt_push_no"
				;;
			(*)
				if [ -z "$invalid_opt" ]; then
					invalid_opt="--$opt_long_identifier"
				fi
				;;
		esac

		unset -v opt_long_identifier

		continue
	fi

	if $process_opts && printf '%s' "$arg" | grep -Eq '^-'; then
		opt_short_chars="${arg#-}"
		i=0

		while [ $i -lt "${#opt_short_chars}" ]; do
			opt_short_char="$(char_at "$opt_short_chars" $i)"

			case "$opt_short_char" in
				('h')
					print_help
					exit
					;;
				('V')
					print_version_info
					exit
					;;
				(*)
					if [ -z "$invalid_opt" ]; then
						invalid_opt="-$opt_short_char"
					fi
					;;
			esac

			unset -v opt_short_char

			i=$((i + 1))
		done

		unset -v i opt_short_chars

		continue
	fi

	if ! $subcommand_set; then
		subcommand="$arg"
		subcommand_set=true
		continue
	fi

	excess_argc=$((excess_argc + 1))
done; unset -v arg

unset -v process_opts

if ! $subcommand_set; then
	{
		printf '%s: missing argument: ( save | restore )\n' "$argv0"
		print_usage
	} >&2
	exit 3
fi

case "$subcommand" in
	('')
		if [ $excess_argc -eq 0 ]; then
			printf '%s: argument must not be empty\n' "$argv0"
		else
			printf '%s: argument #1: must not be empty\n' "$argv0"
		fi >&2
		print_usage >&2

		exit 9
		;;
	('save')
		# ok
		;;
	('restore')
		case "$opt_push" in
			("$opt_push_unspecified")
				# ok
				;;
			("$opt_push_yes")
				{
					printf '%s: restore: --push: invalid option\n' "$argv0"
					print_usage
				} >&2
				exit 5
				;;
			("$opt_push_no")
				printf '%s: restore: --no-push: invalid option\n' "$argv0" >&2
				exit 5
				;;
		esac
		;;
	(*)
		{
			printf '%s: %s: unknown subcommand\n' "$argv0" "$subcommand"
			print_usage
		} >&2
		exit 8
		;;
esac

if [ $excess_argc -gt 0 ]; then
	{
		printf '%s: too many arguments: %s\n' "$argv0" "$excess_argc"
		print_usage
	} >&2
	exit 4
fi

if [ -n "$invalid_opt" ]; then
	printf '%s: %s: invalid option\n' "$argv0" "$invalid_opt" >&2
	exit 5
fi

unset -v invalid_opt excess_argc subcommand_set

# endregion

#region subcommand: save

get_default_wip_commit_message() {
	printf '::: Temporary Commit - WIP Changes :::\n'

	printf '\n'

	printf 'Use\n'
	printf '        git reset --mixed {commit_hash}\n'
	printf 'to reset this commit and continue working.'
}

# $1: commit hash
get_wip_commit_message() {
	set -- "$1" "$(git config get --default='' wip-dump.message)"

	if [ -z "$2" ]; then
		set -- "$1" "$(get_default_wip_commit_message)"
	fi

	printf '%s' "$2" | sed s/'{commit_hash}'/"$1"/g
}

are_commit_hooks_enabled() {
	set -- "$(git config get --type=bool --default='false' wip-dump.commit-hooks-enabled)"

	test "$1" = 'true'
}

git_wip_dump_save() {
	set -- "$(git show --no-patch --pretty=format:%h HEAD)"
	set -- "$(get_wip_commit_message "$1")"

	set -- "$1" "[git-wip-dump: v$(git_wip_dump_version)]"

	git add --all

	if are_commit_hooks_enabled; then
		set -- "$1" "$2" ''
	else
		set -- "$1" "$2" '--no-verify'
	fi
	# shellcheck disable=SC2086
	git commit $3 --message="$1" --message="$2"

	if [ "$opt_push" = "$opt_push_yes" ]; then
		git push --force --verbose --no-verify
	fi
}

#endregion

#region subcommand: restore

# stdin: message
is_commit_message_from_us() {
	grep -Eq '^\[git-wip-dump:[[:space:]]*v0+\.[0-9]+\.[0-9]+(-(indev|rc)[0-9]+)?\]$'
}

git_wip_dump_restore() {
	if ! git show --no-patch --pretty=format:%b HEAD | is_commit_message_from_us; then
		printf 'The currently checked out commit does not appear to be WIP commit created by git-wip-dump. Continue anyway? [y/N] ' >&2

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
	fi

	parent_commit_hashes="$(git show --no-patch --pretty=format:%P HEAD)"

	if printf '%s' "$parent_commit_hashes" | grep -Eq '[^0-9a-fA-F]'; then
		printf '%s: currently checked out commit is a merge commit. Aborting.\n' "$argv0" >&2
		exit 33
	fi

	git reset --mixed "$parent_commit_hashes"
}

#endregion

case "$subcommand" in
	('save')
		git_wip_dump_save
		;;
	('restore')
		git_wip_dump_restore
		;;
esac
