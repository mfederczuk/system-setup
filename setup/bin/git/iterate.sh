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
			printf '%s: missing argument: <commit>\n' "$argv0"
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

		parent_begin_commit="$1"
		;;
	(*)
		{
			printf '%s: too many arguments: %i\n' "$argv0" $(($# - 1))
			print_usage
		} >&2
		exit 4
		;;
esac

unset -f print_usage

readonly parent_begin_commit

#endregion

starts_with() {
	test "${1#"$2"}" != "$1"
}

ends_with() {
	test "${1%"$2"}" != "$1"
}

#region setting up pager command

pager_cmd="$(git --no-pager config --get core.pager)"
pager_cmd="${pager_cmd-"${PAGER-"${SYSTEMD_PAGER-}"}"}"

if starts_with "$pager_cmd" 'less'; then
	pager_cmd="$(printf '%s' "$pager_cmd" | sed -e s/'--quit-if-one-screen'/'-+F'/g -e s/'-F'/'-+F'/g)"

	if ends_with "$pager_cmd" '--'; then
		pager_cmd="${pager_cmd%"--"} -+F --"
	else
		pager_cmd="$pager_cmd -+F"
	fi
fi

readonly pager_cmd

#endregion

#region collecting commits

commit_hashes="$(git --no-pager rev-list --reverse "$parent_begin_commit..HEAD" && printf x)"
commit_hashes="${commit_hashes%x}"
readonly commit_hashes

commits_count=$(( $(printf '%s' "$commit_hashes" | wc -l) ))
readonly commits_count

#endregion

if [ $commits_count -eq 0 ]; then
	printf 'No commits selected; nothing to do.\n' >&2
	exit
fi

#region main loop

print_help() {
	printf '(p) Move to the previous commit\n'
	printf '(n) Move to the next commit / Quit if at the last commit\n'
	printf '(s) Show the current commit\n'
	printf '(q) Quit\n'
	printf '(h) Print this help\n'
	printf '(<nothing> / enter) Show the current commit and then move to the next commit\n'
} >&2

current_commit_nr=1

get_current_commit_hash() {
	printf '%s' "$commit_hashes" | head -n$current_commit_nr | tail -n1
}

move_to_previous_commit() {
	if [ $current_commit_nr -gt 1 ]; then
		current_commit_nr=$((current_commit_nr - 1))
	else
		printf 'Already at first commit\n' >&2
	fi
}

show_current_commit() {
	set -- "$(get_current_commit_hash)" || return

	if [ -n "$pager_cmd" ]; then
		git --paginate \
			-c core.pager="$pager_cmd" \
			-c pager.show=true \
			show "$1"
	else
		git --paginate \
			-c pager.show=true \
			show "$1"
	fi
}

move_to_next_commit() {
	if [  $current_commit_nr -eq $commits_count ]; then
		printf '\nDone.\n' >&2
		exit
	fi

	if [ $current_commit_nr -lt $commits_count ]; then
		current_commit_nr=$((current_commit_nr + 1))
	fi
}

quit() {
	printf '\nBye.\n' >&2
	exit
}

print_prompt() {
	set -- "$(get_current_commit_hash)"

	{
		git --no-pager show --no-patch --pretty="%n%C(blue)================================================================================%C(reset)"
		git --no-pager show --no-patch --pretty="At commit %C(brightgreen)$current_commit_nr%C(reset) of %C(brightgreen)$commits_count%C(reset) - %C(auto)%h %s%C(reset)" "$1"
		git --no-pager show --no-patch --pretty="format:%C(blue)What now%C(reset)> " "$1"
	} >&2
}

print_help

while true; do
	print_prompt

	read -r ans

	case "$ans" in
		('p')
			move_to_previous_commit
			;;
		('n')
			move_to_next_commit
			;;
		('s')
			show_current_commit
			;;
		('q')
			quit
			;;
		('h')
			print_help
			;;
		('')
			show_current_commit
			move_to_next_commit
			;;
		(*)
			printf 'Unknown command: %s\n' "$ans" >&2
			;;
	esac

	unset -v ans
done

#endregion
