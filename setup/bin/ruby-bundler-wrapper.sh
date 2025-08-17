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

home_dir_path="${HOME-}"
readonly home_dir_path

if [ -z "$home_dir_path" ]; then
	printf '%s: environment variable HOME is unset or empty\n' "$argv0" >&2
	exit 48
fi


print_usage() {
	printf 'usage: %s (bundler|bundle) [<args>...]\n' "$argv0"
}

if [ $# -lt 1 ]; then
	{
		printf '%s: missing arguments: (bundler|bundle) [<args>...]\n' "$argv0"
		print_usage
	} >&2
	exit 3
fi

case "$1" in
	('bundler'|'bundle') ;;
	('')
		if [ $# = 1 ]; then
			printf '%s: argument must not be empty\n' "$argv0" >&2
		else
			printf '%s: argument 1: must not be empty\n' "$argv0" >&2
		fi
		print_usage >&2
		exit 9
		;;
	(*)
		{
			printf "%s: %s: invalid argument: must be either 'bundler' or 'bundle'\\n" "$argv0" "$1"
			print_usage
		} >&2
		exit 7
		;;
esac

unset -f print_usage


home_bin_dir_path="$home_dir_path/bin"
readonly home_bin_dir_path

if [ -e "$home_bin_dir_path" ]; then
	{
		printf '[bundler wrapper] ~/bin exists already. The wrapper script will NOT check if it\n'
		printf '[bundler wrapper] was changed after executing Bundler. Continue? [y/N] '
	} >&2

	read -r answer

	case "$answer" in
		(['Yy']*)
			{
				printf "[bundler wrapper] You're on your own.\\n"
				printf -- '-------------------------------------------------------------------------------\n'
			} >&2

			exec "$@"
			;;
		(['Nn']*|'')
			printf '[bundler wrapper] Aborted.\n' >&2
			exit 32
			;;
	esac
fi

exc=0
"$@" || exc=$?
readonly exc


if [ -e "$home_bin_dir_path" ]; then
	{
		printf -- '-------------------------------------------------------------------------------\n'
		printf '[bundler wrapper] Bundler created ~/bin! Recursively remove it again? [Y/n] '
	} >&2

	read -r answer

	case "$answer" in
		(['Yy']*|'')
			{
				printf '[bundler wrapper] Removing ~/bin...\n'
				rm -rf -- "$home_bin_dir_path"
				printf '[bundler wrapper] Successfully removed ~/bin\n'
			} >&2
			;;
		(['Nn']*)
			printf '[bundler wrapper] Keeping ~/bin.\n' >&2
			;;
	esac

	unset -v answer
fi

exit $exc
