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

if [ "${0#/}" = "$0" ]; then
	argv0="$0"
else
	argv0="$(basename -- "$0" && printf x)"
	argv0="${argv0%"$(printf '\nx')"}"
fi
readonly argv0

#endregion

if [ $# -gt 0 ]; then
	printf '%s: too many arguments: %i\n' "$argv0" $# >&2
	exit 4
fi

workspace_storage_dir_pathname="${XDG_CONFIG_HOME:-"$HOME/.config"}/VSCodium/User/workspaceStorage"
readonly workspace_storage_dir_pathname

if [ ! -d "$workspace_storage_dir_pathname" ]; then
	exit
fi

if ! command -v jq > '/dev/null'; then
	printf '%s: jq: program missing\n' "$argv0" >&2
	exit 27
fi

for workspace_dir_pathname in "$workspace_storage_dir_pathname/"*; do
	if [ ! -d "$workspace_dir_pathname" ]; then
		continue
	fi

	should_delete_workspace_dir=false

	if [ ! -f "$workspace_dir_pathname/workspace.json" ]; then
		should_delete_workspace_dir=true
	fi

	if ! $should_delete_workspace_dir; then
		workspace_folder_location="$(jq -rM '."folder"' "$workspace_dir_pathname/workspace.json")"
		workspace_folder_location="${workspace_folder_location#"file://"}"

		if [ ! -d "$workspace_folder_location" ]; then
			should_delete_workspace_dir=true
		fi

		unset -v workspace_folder_location
	fi

	if $should_delete_workspace_dir; then
		rm -rf -- "$workspace_dir_pathname"
		printf "Removed '%s'\\n" "$workspace_dir_pathname" >&2
	fi

	unset -v should_delete_workspace_dir
done
