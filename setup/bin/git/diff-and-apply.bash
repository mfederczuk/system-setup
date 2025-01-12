#!/bin/bash
# -*- sh -*-
# vim: syntax=sh
# code: language=shellscript

# Copyright (c) 2024 Michael Federczuk
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

set -o pipefail

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

#region collecting git-diff arguments

declare -a diff_args_pre_dash_dash
diff_args_pre_dash_dash=()

declare -a diff_args_post_dash_dash
diff_args_post_dash_dash=()

declare is_post_dash_dash
is_post_dash_dash=false

declare diff_arg
for diff_arg in "$@"; do
	if $is_post_dash_dash; then
		diff_args_post_dash_dash+=("$diff_arg")
		continue
	fi

	if [ "$diff_arg" = '--' ]; then
		is_post_dash_dash=true
		continue
	fi

	diff_args_pre_dash_dash+=("$diff_arg")
done
unset -v diff_arg

unset -v is_post_dash_dash

readonly diff_args_post_dash_dash diff_args_pre_dash_dash

#endregion

function git_plumbing() {
	git -c diff.noprefix=false --no-pager "$@"
}

function git_rawdiff() {
	git_plumbing diff "${diff_args_pre_dash_dash[@]}" \
	                  --patch-with-raw -z --no-color --full-index --binary \
	                  -- "${diff_args_post_dash_dash[@]}"
}

#region empty diff check

declare -i rawdiff_size
rawdiff_size="$(git_rawdiff | wc -c)"

if ((rawdiff_size == 0)); then
	printf 'Nothing to do. (empty diff)\n' >&2
	exit
fi

unset -v rawdiff_size

#endregion

#region showing diff

function is_only_diffstat() {
	local is_stat_requested
	is_stat_requested=false

	local diff_arg
	for diff_arg in "${diff_args_pre_dash_dash[@]}"; do
		if [[ "$diff_arg" =~ ^('-'.*['pu'].*|'--patch'|'--patch-with-raw'|'--patch-with-stat')$ ]]; then
			return 32
		fi

		if [[ "$diff_arg" =~ ^('--stat'('='.*)?|'--numstat'|'--short')$ ]]; then
			is_stat_requested=true
			continue
		fi
	done

	if $is_stat_requested; then
		return 0
	else
		return 32
	fi
}

if is_only_diffstat; then
	git --no-pager diff "${diff_args_pre_dash_dash[@]}" -- "${diff_args_post_dash_dash[@]}"
else
	git --paginate diff "${diff_args_pre_dash_dash[@]}" -- "${diff_args_post_dash_dash[@]}"

	git --no-pager diff "${diff_args_pre_dash_dash[@]}" --no-patch --stat -- "${diff_args_post_dash_dash[@]}"
fi >&2

unset -f is_only_diffstat

#endregion

#region prompting

{
	printf '\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n'
	printf 'Apply these patches to the current working tree? [Y/n] '
} >&2

read -r ans

case "$ans" in
	([yY]*|'')
		# continue
		;;
	(*)
		printf 'Aborted.\n' >&2
		exit 48
		;;
esac

unset -v ans

#endregion

git_rawdiff | git_plumbing apply
