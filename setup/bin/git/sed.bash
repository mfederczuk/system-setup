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
	# when executing script through git - i.e.: `git <command>`

	argv0="$(basename -- "$0" && printf x)"
	argv0="${argv0%$'\nx'}"
	argv0="git ${argv0#"git-"}"
else
	# when executing script directly

	if [ "${0#/}" = "$0" ]; then
		argv0="$0"
	else
		argv0="$(basename -- "$0" && printf x)"
		argv0="${argv0%$'\nx'}"
	fi
fi
readonly argv0

#endregion

#region checking for GNU sed

declare sed_version_info

if ! sed_version_info="$(command sed --version 2> '/dev/null')" \
   && [[ ! "$sed_version_info" =~ ^'sed (GNU sed)' ]]; then

	printf '%s: GNU sed is required' "$argv0" >&2
	exit 48
fi

unset -v sed_version_info

#endregion

function ensure_pathname_doesnt_start_with_dash() {
	local pathname || return
	pathname="$1" || return
	readonly pathname || return

	if [[ ! "$pathname" =~ ^'-' ]]; then
		printf '%s' "$pathname"
		return
	fi

	printf './%s' "$pathname"
}
readonly -f ensure_pathname_doesnt_start_with_dash

#region collecting untracked paths

declare -a untracked_pathnames
untracked_pathnames=()

declare status pathname
while read -r -d '' -u 3; do
	status="${REPLY:0:2}"
	pathname="${REPLY:3}"

	if [ "$status" != '??' ] || [ ! -f "$pathname" ]; then
		continue
	fi

	if ((${#untracked_pathnames[@]} == 0)); then
		printf 'The working tree contains untracked files. Include them as well? [Y/n] ' >&2

		read -r ans

		case "$ans" in
			(['Yy']*|'')
				unset -v ans
				;;
			(*)
				unset -v ans
				break
				;;
		esac
	fi

	pathname="$(ensure_pathname_doesnt_start_with_dash "$pathname")"

	untracked_pathnames+=("$pathname")
done 3< <(git -c status.renames=false status --porcelain=v1 --untracked-files=all --ignored=no -z --no-renames)
unset -v pathname status

readonly untracked_pathnames

#endregion

#region collecting tree paths

declare -a pathnames
pathnames=()

declare pathname
while read -r -d ''; do
	pathname="$REPLY"

	if [ ! -f "$pathname" ]; then
		continue
	fi

	pathname="$(ensure_pathname_doesnt_start_with_dash "$pathname")"

	pathnames+=("$pathname")
done < <(git --no-pager ls-tree -r -z --name-only --full-tree HEAD)
unset -v pathname

pathnames+=("${untracked_pathnames[@]}")

readonly pathnames

#endregion

if ((${#pathnames[@]} == 0)); then
	printf 'No paths to edit.\n' >&2
	exit
fi

sed -i "$@" "${pathnames[@]}"
