#!/bin/sh
# -*- sh -*-
# vim: syntax=sh
# code: language=shellscript

# Copyright (c) 2025 Michael Federczuk
# SPDX-License-Identifier: MPL-2.0 AND Apache-2.0

# TODO: Rewrite this in a multi-threaded language to add the option --parallel. (along with --fail-fast)
#       At that point, this should be extracted into its own repository probably.

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

#region Processing arguments

print_usage() {
	printf 'usage: %s <commit-ish|revision-range> -- <command>\n' "$argv0"
}

if [ "${1-}" = '--help' ]; then
	print_usage
	exit
fi

if [ $# -lt 1 ]; then
	{
		printf '%s: missing arguments: <commit-ish|revision-range> -- <command>\n' "$argv0"
		print_usage
	} >&2
	exit 3
fi
if [ -z "$1" ]; then
	{
		printf '%s: argument 1: must not be empty\n' "$argv0"
		print_usage
	} >&2
	exit 9
fi
committish_or_revision_range="$1"
readonly committish_or_revision_range

if [ $# -lt 2 ]; then
	{
		printf '%s: missing arguments: -- <command>\n' "$argv0"
		print_usage
	} >&2
	exit 3
fi
if [ "$2" != '--' ]; then
	if [ -z "$2" ]; then
		{
			printf '%s: argument 2: must not be empty\n' "$argv0"
			print_usage
		} >&2
		exit 9
	else
		{
			printf "%s: %s: invalid argument: must be the string '--'\\n" "$argv0" "$2"
			print_usage
		} >&2
		exit 7
	fi
fi

if [ $# -lt 3 ]; then
	{
		printf '%s: missing argument: <command>\n' "$argv0"
		print_usage
	} >&2
	exit 3
fi
if [ -z "$3" ]; then
	{
		printf '%s: argument 3: must not be empty\n' "$argv0"
		print_usage
	} >&2
	exit 9
fi
command="$3"
readonly command

if [ $# -gt 3 ]; then
	{
		printf '%s: too many arguments: %d\n' "$argv0" $(($# - 3))
		print_usage
	} >&2
	exit 4
fi

unset -f print_usage

#endregion

#region Collecting Commits

exc=0
tmp="$(git --no-pager rev-parse --verify --quiet --end-of-options "$committish_or_revision_range")" ||
	exc=$?

case $exc in
	(0)
		commit_hashes="$tmp"
		commits_count=1
		;;
	(1)
		if [ -z "$tmp" ]; then
			printf "fatal: bad revision '%s'\\n" "$committish_or_revision_range" >&2
			exit 128
		fi

		set -o noglob
		# shellcheck disable=SC2046
		commit_hashes="$(git --no-pager rev-list --reverse $(printf '%s' "$tmp" | tr -s '[:space:]' ' ') && printf x)"
		set +o noglob

		commit_hashes="${commit_hashes%x}"
		commits_count=$(( $(printf '%s' "$commit_hashes" | wc -l) ))
		;;
	(*)
		exit $exc
		;;
esac

readonly commit_hashes
readonly commits_count
unset -v tmp exc

#endregion

case $commits_count in
	(0)
		printf 'No commits to process\n' >&2
		exit
		;;
	(1)
		printf 'Processing one commit...\n' >&2
		;;
	(*)
		printf 'Processing %d commits...\n' $commits_count >&2
		;;
esac

#region Setting up the working directory

working_dir_path="${GIT_RUN_WORKING_DIR-}"

if [ -z "$working_dir_path" ]; then
	remove_working_dir() {
		rm -rf -- "$working_dir_path"
	}

	base_tmp_dir_path="${TMPDIR:-"${TMP:-"${TEMP:-"${TEMPDIR:-"${TMP_DIR:-"${TEMP_DIR:-"/tmp"}"}"}"}"}"}"

	if command -v mktemp > '/dev/null' && { mktemp --version 2>&1 | head -n1 | grep -Eq '^mktemp \(GNU coreutils\)'; }; then
		working_dir_path="$(mktemp --directory --tmpdir="$base_tmp_dir_path" 'git-run-isolated-working-directory.XXXXXXXXXX')"
	else
		working_dir_path="$base_tmp_dir_path/git-run-isolated-working-directory-$(id -u)-$$"

		mkdir -p -- "$working_dir_path"

		# shellcheck disable=SC2283
		chmod -- =700 "$working_dir_path"
	fi

	unset -v base_tmp_dir_path

	trap remove_working_dir EXIT
	trap 'trap - EXIT; remove_working_dir' INT QUIT TERM
fi

readonly working_dir_path

#endregion

# TODO: Optimize by creating a shallow clone? Would need to determine the oldest commits in the revision range.
git clone --no-local --no-hardlinks --quiet --bare --mirror --tags -- '.' "$working_dir_path/source.git"

cd -- "$working_dir_path/source.git"

for commit_hash in $commit_hashes; do
	git tag -- "__git-run-isolated/revisions/$commit_hash" "$commit_hash"
done

cd -- '..'
mkdir -p -- 'revisions'

#region Running commands

current_commit_nr=0

print_separator() {
	set -- 0 "${COLUMNS-80}" ''

	while [ "$1" -lt "$2" ]; do
		set -- $(($1 + 1)) "$2" "$3="
	done

	git --no-pager show --no-patch --pretty="%C(blue)$3%C(reset)" HEAD
}
print_command_info() {
	set -- "$(printf '%s' "$command" | sed -s s/'%'/'%%'/g)"
	git --no-pager show --no-patch --pretty="Executing command %C(yellow)\`$1\`%C(reset)" HEAD
}
if [ $commits_count -eq 1 ]; then
	print_commit_info() {
		{
			print_separator
			git --no-pager show --no-patch --pretty="Commit %C(auto)%h %s%C(reset)" HEAD
			print_command_info
		} >&2
	}
else
	print_commit_info() {
		{
			print_separator
			git --no-pager show --no-patch --pretty="At commit %C(brightgreen)$current_commit_nr%C(reset) of %C(brightgreen)$commits_count%C(reset) - %C(auto)%h %s%C(reset)" HEAD
			print_command_info
		} >&2
	}
fi

for commit_hash in $commit_hashes; do
	printf '\n' >&2

	current_commit_nr=$((current_commit_nr + 1))

	git -c advice.detachedHead=false \
	    clone --local \
	          --quiet \
	          --branch="__git-run-isolated/revisions/$commit_hash" \
	          --single-branch \
	          --tags \
	          --recurse-submodules \
	          --shallow-submodules \
	          -- \
	          'source.git' "revisions/$commit_hash"

	(
		cd -- "revisions/$commit_hash"

		for commit_hash2 in $commit_hashes; do
			git tag --delete -- "__git-run-isolated/revisions/$commit_hash2" > '/dev/null'
		done
		unset -v commit_hash2

		print_commit_info

		printf '\n' >&2

		"${SHELL-"/bin/sh"}" -c "$command"
	)

	rm -rf -- "revisions/$commit_hash"
done

#endregion
