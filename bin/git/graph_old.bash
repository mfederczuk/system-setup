#!/bin/bash
# -*- sh -*-
# vim: syntax=sh
# code: language=shellscript

# Copyright (c) 2023 Michael Federczuk
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

# asserts that we're in a repository and at least one commit exists
git --no-pager show 1> '/dev/null'

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

#region args

declare -a extra_git_log_args
extra_git_log_args=()

declare refs_behavior \
        stashes_behavior \
        unreachable_commits_included \
        commit_author_names_included commit_author_emails_included \
        additional_newline_included
refs_behavior='default'
stashes_behavior='default'
unreachable_commits_included=false
commit_author_names_included=false
commit_author_emails_included=false
additional_newline_included=false

declare processing_opts
processing_opts=true

declare arg
for arg in "$@"; do
	if $processing_opts && ((${#arg} >= 2)) && [[ "$arg" =~ ^'--' ]]; then
		if [ "$arg" = '--' ]; then
			processing_opts=false
			extra_git_log_args+=('--')
			continue
		fi

		declare consumed

		declare opt_id
		opt_id="${arg#"--"}"

		case "$opt_id" in
			('all')
				refs_behavior='none'
				stashes_behavior='included'
				consumed=false
				;;
			('branches')
				refs_behavior='none'
				consumed=false
				;;
			('remotes')
				refs_behavior='none'
				consumed=false
				;;
			('tags')
				refs_behavior='none'
				consumed=false
				;;
			('local')
				refs_behavior='local'
				stashes_behavior='included'
				consumed=true
				;;

			('stashes')
				stashes_behavior='included'
				consumed=true
				;;
			('no-stashes')
				stashes_behavior='excluded'
				consumed=true
				;;

			('unreachable')
				unreachable_commits_included=true
				consumed=true
				;;
			('no-unreachable')
				unreachable_commits_included=false
				consumed=true
				;;

			('names')
				commit_author_names_included=true
				consumed=true
				;;
			('no-names')
				commit_author_names_included=false
				consumed=true
				;;

			('emails')
				commit_author_emails_included=true
				consumed=true
				;;
			('no-emails')
				commit_author_emails_included=false
				consumed=true
				;;

			('ln')
				additional_newline_included=true
				consumed=true
				;;
			('no-ln')
				additional_newline_included=false
				consumed=true
				;;

			(*)
				consumed=false
				;;
		esac

		unset -v opt_id

		if $consumed; then
			unset -v consumed
			continue
		fi

		unset -v consumed
	fi

	extra_git_log_args+=("$arg")
done
unset -v arg

unset -v processing_opts

readonly additional_newline_included \
         commit_author_emails_included commit_author_names_included \
         unreachable_commits_included \
         stashes_behavior \
         refs_behavior

readonly extra_git_log_args

#endregion

#region ref options

declare -a ref_options
ref_options=()

if [ "$refs_behavior" = 'local' ]; then
	ref_options+=('--exclude=refs/remotes/*')
fi

case "$refs_behavior" in
	('default'|'local')
		ref_options+=('--all')
		;;
esac

readonly ref_options

#endregion

#region stashes

declare -a stash_hashes
stash_hashes=()

if [ "$stashes_behavior" = 'included' ] ||
   { [ "$stashes_behavior" = 'default' ] && [ "$refs_behavior" = 'default' ]; }; then

	mapfile -t stash_hashes < <(git --no-pager reflog show --format='%h' stash 2> '/dev/null')
fi

readonly stash_hashes

#endregion

#region unreachable commits

declare -a unreachable_commit_hashes
unreachable_commit_hashes=()

if $unreachable_commits_included; then
	mapfile -t unreachable_commit_hashes < <(git --no-pager fsck --no-progress --unreachable |
		                                         sed -ne s/'^.*commit \([A-Fa-f0-9][A-Fa-f0-9]*\)$'/'\1'/p)
fi

readonly unreachable_commit_hashes

#endregion

#region pretty format

# cSpell:ignore mboxrd tformat

# see section "PRETTY FORMATS" in man pages git-log(1) or git-show(1) (and possible others)
#
# There are three types of <pretty formats>: <builtins>, <aliases> and <format strings>
#
# <builtins> are one the following exact strings (case sensitive; must be lowercase):
#  * "oneline"
#  * "short"
#  * "medium"
#  * "full"
#  * "fuller"
#  * "reference"
#  * "email"
#  * "mboxrd"
#  * "raw"
#
# <format strings> are either any strings that contain a <percent sign> ('%') or any strings that begin with either
# "format:" or "tformat:".
#
# <aliases> are all other strings.

#region pretty_format_* functions

# normally functions names should begin with "is_", "determine_", ...  but the prefix "pretty_format_" here is used as
# a namespace (like how it'd be done in C)

function pretty_format_is_builtin() {
	[[ "$1" =~ ^('oneline'|'short'|'medium'|'full'|'fuller'|'reference'|'email'|'mboxrd'|'raw')$ ]]
}

function pretty_format_is_format_string() {
	[[ "$1" =~ ((^$)|(^('t')?'format:')|'%') ]]
}

function pretty_format_is_alias() {
	! pretty_format_is_builtin "$1" &&
		! pretty_format_is_format_string "$1"
}

function pretty_format_determine_type() {
	if pretty_format_is_builtin "$1"; then
		printf 'builtin'
		return
	fi

	if pretty_format_is_format_string "$1"; then
		printf 'format_string'
		return
	fi

	printf 'alias'
}

function pretty_format_does_alias_exist() {
	pretty_format_is_alias "$1" &&
		git --no-pager config --get "pretty.$1" > '/dev/null'
}

#endregion

#             |            --no-nl               |               --ln
# ------------+----------------------------------+-------------------------------------
# --no-names  | graph-default                    | graph-default-ln
#    --names  | graph-with-author-name           | graph-with-author-name-ln
#    --emails | graph-with-author-name-and-email | graph-with-author-name-and-email-ln

declare pretty_format
pretty_format='graph-default'

if $commit_author_names_included; then
	pretty_format='graph-with-author-name'
fi

if $commit_author_emails_included; then
	pretty_format='graph-with-author-name-and-email'
fi

if $additional_newline_included; then
	declare no_ln_pretty_format
	no_ln_pretty_format="$pretty_format"

	declare ln_pretty_format
	ln_pretty_format="$no_ln_pretty_format-ln"

	if ! pretty_format_does_alias_exist "$ln_pretty_format"; then
		if ! pretty_format_does_alias_exist "$no_ln_pretty_format"; then
			printf "%s: neither pretty format alias '%s' nor '%s' exist\\n" "$argv0" "$no_ln_pretty_format" "$ln_pretty_format" >&2
			exit 48
		fi

		declare tmp_pretty_format
		tmp_pretty_format="$(git --no-pager config --get "pretty.$no_ln_pretty_format")"

		while pretty_format_is_alias "$tmp_pretty_format"; do
			if ! pretty_format_does_alias_exist "$tmp_pretty_format"; then
				printf '%s'
			fi

			tmp_pretty_format="$(git --no-pager config --get "pretty.$tmp_pretty_format")"
		done

		case "$(pretty_format_determine_type "$tmp_pretty_format")" in
			('builtin')
				{
					printf "%s: the pretty format alias '%s' resolves to a built-in pretty format ('%s')\\n" "$argv0" "$no_ln_pretty_format" "$tmp_pretty_format"
					printf '%s: for the option --ln this alias must resolve to a format string\n' "$argv0"
				} >&2
				exit 49
				;;
			('format_string')
				# ok
				;;
			('alias')
				printf '%s: \n' "$argv0" >&2
				# TODO: fail, shouldn't happen
				exit 1
				;;
			(*)
				printf '%s: \n' "$argv0" >&2
				# TODO: fail, shouldn't happen
				exit 1
				;;
		esac

		ln_pretty_format="${tmp_pretty_format}%n"
		unset -v tmp_pretty_format
	fi

	pretty_format="$ln_pretty_format"
	unset -v no_ln_pretty_format ln_pretty_format
fi

if [ "$pretty_format" = 'graph-default' ] && ! pretty_format_does_alias_exist "$pretty_format"; then
	pretty_format='oneline'
fi

if pretty_format_is_alias "$pretty_format" && ! pretty_format_does_alias_exist "$pretty_format"; then
	printf '%s: \n' "$argv0" >&2
	exit 1 # TODO: fail
fi

readonly pretty_format

unset -f pretty_format_does_alias_exist \
         pretty_format_determine_type \
         pretty_format_is_alias \
         pretty_format_is_format_string \
         pretty_format_is_builtin

#endregion

git log --graph --pretty="$pretty_format" \
        "${ref_options[@]}" \
        "${stash_hashes[@]}" \
        "${unreachable_commit_hashes[@]}" \
        "${extra_git_log_args[@]}"
