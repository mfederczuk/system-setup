#!/bin/sh
# -*- sh -*-
# vim: set syntax=sh
# code: language=shellscript

# Copyright (c) 2022 Michael Federczuk
# SPDX-License-Identifier: MPL-2.0 AND Apache-2.0

# <https://github.com/mfederczuk/git-wip-dump/blob/v0.1.0/git-wip-dump>

set -o errexit
set -o nounset

# POSIX compliant mode for GNU programs
export POSIXLY_CORRECT=yes POSIX_ME_HARDER=yes

# asserts that we're in a repository and at least one commit exists
git --no-pager show 1> '/dev/null'

# $1: string
# $2: char index
char_at() {
	printf '%s' "$1" | dd bs=1 count=1 skip="$2" 2> '/dev/null'
}

readonly git_wip_dump_version_major=0
readonly git_wip_dump_version_minor=1
readonly git_wip_dump_version_patch=0
readonly git_wip_dump_version_pre_release=''
git_wip_dump_version() {
	printf '%i.%i.%i' "$git_wip_dump_version_major" "$git_wip_dump_version_minor" "$git_wip_dump_version_patch"

	if [ -n "$git_wip_dump_version_pre_release" ]; then
		printf '%s' "-$git_wip_dump_version_pre_release"
	fi
}

if [ -n "${GIT_EXEC_PATH-}" ]; then
	# when executing script through git - i.e.: `git wip-dump`
	argv0="$(basename "$0")"
	argv0="git $(printf '%s' "$argv0" | sed -e s/'^git-\(..*\)$'/'\1'/)"
else
	# when executing script directly
	argv0="$0"

	if printf '%s' "$argv0" | grep -Eq '^/'; then
		argv0="$(basename "$argv0")"
	fi
fi
readonly argv0

# region args

print_usage() {
	{
		echo "usage: $argv0 save [--push]"
		echo "   or: $argv0 restore"
	} >&2
}

print_help() {
	print_usage
	{
		echo
		echo '    --push                also push the created commit to the tracked upstream'
	} >&2
}

print_version_info() {
	{
		echo "git-wip-dump $(git_wip_dump_version)"
		echo
		echo 'Copyright (C) 2022 Michael Federczuk'
		echo
		echo '    License MPL-2.0: Mozilla Public License 2.0 <https://www.mozilla.org/en-US/MPL/2.0/>'
		echo '            AND'
		echo '    License Apache-2.0: Apache License 2.0 <https://www.apache.org/licenses/LICENSE-2.0>'
		echo
		echo 'This is free software: you are free to change and redistribute it.'
		echo 'There is NO WARRANTY, to the extent permitted by law.'
		echo
		echo 'Written by Michael Federczuk.'
	} >&2
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
	echo "$argv0: missing argument: ( save | restore )" >&2
	print_usage
	exit 3
fi

case "$subcommand" in
	('')
		if [ $excess_argc -eq 0 ]; then
			echo "$argv0: argument must not be empty" >&2
		else
			echo "$argv0: argument #1: must not be empty" >&2
		fi
		print_usage

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
				echo "$argv0: restore: --push: invalid option" >&2
				print_usage
				exit 5
				;;
			("$opt_push_no")
				echo "$argv0: restore: --no-push: invalid option" >&2
				exit 5
				;;
		esac
		;;
	(*)
		echo "$argv0: $subcommand: unknown subcommand" >&2
		print_usage
		exit 8
		;;
esac

if [ $excess_argc -gt 0 ]; then
	echo "$argv0: too many arguments: $excess_argc" >&2
	print_usage
	exit 4
fi

if [ -n "$invalid_opt" ]; then
	echo "$argv0: $invalid_opt: invalid option" >&2
	exit 5
fi

unset -v invalid_opt excess_argc subcommand_set

# endregion

git_wip_dump_save() {
	nl="$(printf '\nx')"
	nl="${nl%x}"

	commit_hash="$(git --no-pager show --no-patch --pretty=format:%h HEAD)"

	commit_message_subject_line='::: Temporary Commit - WIP Changes :::'
	commit_message_body_paragraph1="Use${nl}        git reset --mixed ${commit_hash}${nl}to reset this commit and continue working."
	commit_message_body_paragraph2="[git-wip-dump: v$(git_wip_dump_version)]"

	git --no-pager add --all

	git --no-pager commit --no-verify \
	                      --message="$commit_message_subject_line"    \
	                      --message="$commit_message_body_paragraph1" \
	                      --message="$commit_message_body_paragraph2"

	if [ "$opt_push" = "$opt_push_yes" ]; then
		git --no-pager push --force --verbose --no-verify
	fi
}

git_wip_dump_restore() {
	if ! git --no-pager show --no-patch --pretty=format:%b HEAD | grep -Eq '^\[git-wip-dump:[[:space:]]*v0+\.[0-9]+\.[0-9]+(-(indev|rc)[0-9]+)?\]$'; then
		printf 'this does not appear to be WIP commit created by git-wip-dump. Continue? [y/N] ' >&2

		read -r ans
		case "$ans" in
			(['yY']*)
				# continue
				;;
			(*)
				echo "aborted." >&2
				exit 32
				;;
		esac
	fi

	parent_commit_hashes="$(git --no-pager show --no-patch --pretty=format:%P HEAD)"

	if printf '%s' "$parent_commit_hashes" | grep -Eq '[^0-9a-fA-F]'; then
		echo "fatal: HEAD has multiple parents (is a merge). aborting." >&2
		exit 33
	fi

	git --no-pager reset --mixed "$parent_commit_hashes"
}

case "$subcommand" in
	('save')
		git_wip_dump_save
		;;
	('restore')
		git_wip_dump_restore
		;;
esac
