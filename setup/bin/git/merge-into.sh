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

#region utils

starts_with() {
	# not using `grep` because it works line-by-line; if the prefix substring ($2) would appear after a newline in the
	# middle of the base string ($1), grep would falsely match
	test "${1#"$2"}" != "$1"
}

#endregion

#region args

base_branch='empty:'
source_branch_deletion_requested=false

print_usage() {
	printf 'usage: %s [-d] <base_branch>\n' "$argv0"
}

print_help() {
	print_usage
	printf "    Merge the current branch into <base_branch> using 'git merge --no-ff'.\\n"
	printf '\n'
	printf '    Options:\n'
	printf '      -d, --delete     delete the source branch after a successful merge\n'
	printf '      -D, --no-delete  do not delete the source branch (default)\n'
	printf '\n'
	printf '      -h, --help  show this summary and exit\n'
}

first_invalid_option=''
excess_operands_count=0

processing_options=true

for arg in "$@"; do
	if $processing_options && [ "$arg" = '--' ]; then
		processing_options=false
		continue
	fi

	if $processing_options && starts_with "$arg" '--'; then
		option_id="${arg#"--"}"

		case "$option_id" in
			('help')
				print_help
				exit 0
				;;
			('delete')
				source_branch_deletion_requested=true
				;;
			('no-delete')
				source_branch_deletion_requested=false
				;;
			(*)
				if [ -z "$first_invalid_option" ]; then
					first_invalid_option="--$option_id"
				fi
				;;
		esac

		unset -v option_id

		continue
	fi

	if $processing_options && [ "$arg" != '-' ] && starts_with "$arg" '-'; then
		option_ids="${arg#"-"}"

		while [ ${#option_ids} -gt 0 ]; do
			option_id="${option_ids%"${option_ids%?}"}"

			case "$option_id" in
				('h')
					print_help
					exit 0
					;;
				('d')
					source_branch_deletion_requested=true
					;;
				('D')
					source_branch_deletion_requested=false
					;;
				(*)
					if [ -z "$first_invalid_option" ]; then
						first_invalid_option="-$option_id"
					fi
					;;
			esac

			option_ids="${option_ids#"$option_id"}"

			unset -v option_id
		done

		unset -v option_ids

		continue
	fi

	if starts_with "$base_branch" 'present:'; then
		excess_operands_count=$((excess_operands_count + 1))
		continue
	fi

	base_branch="present:$arg"
done
unset -v arg

unset -v processing_options

if [ "$base_branch" = 'empty:' ]; then
	printf '%s: missing argument: <base_branch>\n' "$argv0" >&2
	print_usage >&2
	exit 3
fi

base_branch="${base_branch#"present:"}"

if [ -z "$base_branch" ]; then
	if [ $excess_operands_count -eq 0 ]; then
		printf '%s: argument must not be empty\n' "$argv0" >&2
	else
		printf '%s: argument 1: must not be empty\n' "$argv0" >&2
	fi
	print_usage
	exit 9
fi

if [ $excess_operands_count -gt 0 ]; then
	printf '%s: too many arguments: %i\n' "$argv0" $excess_operands_count >&2
	print_usage >&2
	exit 4
fi
unset -v excess_operands_count

if [ -n "$first_invalid_option" ]; then
	printf '%s: %s: invalid option\n' "$argv0" "$first_invalid_option" >&2
	print_usage >&2
	exit 5
fi
unset -v first_invalid_option

unset -f print_help print_usage

readonly source_branch_deletion_requested base_branch

#endregion

#region determining current branch

if $source_branch_deletion_requested; then
	source_branch="$(git --no-pager rev-parse --abbrev-ref HEAD)"
	readonly source_branch

	if [ "$source_branch" = 'HEAD' ]; then
		printf '%s: cannot delete source branch in detached HEAD state\n' "$argv0" >&2
		exit 48
	fi
fi

#endregion

#region main

git switch -- "$base_branch"
git merge --no-ff -- -

if $source_branch_deletion_requested; then
	git branch --delete -- "$source_branch"
fi

#endregion
