#!/bin/sh
# -*- sh -*-
# vim: syntax=sh
# code: language=shellscript

# Copyright (c) 2025 Michael Federczuk
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

if [ "${0#/}" = "$0" ]; then
	argv0="$0"
else
	argv0="$(basename -- "$0" && printf x)"
	argv0="${argv0%"$(printf '\nx')"}"
fi
readonly argv0

#endregion

get_top_level_original_working_tree_path() {
	set -- "${GIT_DIR:-".git"}"
	set -- "$1" "$(git --no-pager rev-parse --show-toplevel)"

	if [ ! -f "$2/$1" ]; then
		printf '%s' "$2"
		return
	fi

	set -- "$1" "$2" "$(cat -- "$2/$1")"
	set -- "$1" "$2" "$3" "${3#"gitdir: "}"

	if [ "$3" = "$4" ]; then
		printf '%s' "$2"
		return
	fi

	set -- "${4%"/$1/worktrees/"*}"
	printf '%s' "$1"
}

if [ -z "${SSH_CONNECTION-}" ] && command -v codium > '/dev/null'; then
	top_level_original_working_tree_path="$(get_top_level_original_working_tree_path)"
	readonly top_level_original_working_tree_path

	exec codium --wait --new-window "$top_level_original_working_tree_path" "$@"
fi

if command -v nvim > '/dev/null'; then
	# Option '-n' => use memory instead of swap file.
	exec nvim -n "$@"
fi

if command -v vim > '/dev/null'; then
	# Option '-n' => use memory instead of swap file.
	exec vim -n "$@"
fi

printf '%s: no preferred editor command available\n' "$argv0" >&2
exit 48
