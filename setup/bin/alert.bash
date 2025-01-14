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

declare argv0
if [[ ! "$0" =~ ^'/' ]]; then
	argv0="$0"
else
	argv0="$(basename -- "$0" && printf x)"
	argv0="${argv0%$'\nx'}"
fi
readonly argv0

#endregion

#region prerequisites

if ! command -v notify-send > '/dev/null'; then
	printf '%s: notify-send: program missing\n' "$argv0" >&2
	exit 27
fi

#endregion

#region args

if [ $# -eq 0 ]; then
	{
		printf '%s: missing argument: <command>\n' "$argv0"
		printf 'usage: %s <command> [<args>...]\n' "$argv0"
	} >&2
	exit 3
fi

#endregion

declare -a args
args=("$@")
readonly args

#region command line string building

declare command_line

function pretty_quote() {
	local str || return
	str="$1" || return
	readonly str || return

	#region quoting string

	local quoted_str || return

	if [[ "$str" =~ ^[A-Za-z0-9_./:+,=-]+$ ]]; then
		# a string that contains only regular characters that don't need escaping or quoting doesn't need to be quoted

		quoted_str="$str" || return
	elif [[ "$str" =~ '!' ]]; then
		# exclamation marks can't be properly escaped in double quotation marks, which is why we force
		# single quotation marks in that case

		quoted_str="$str"                       || return
		quoted_str="${quoted_str//\'/\'\\\'\'}" || return #     'foo!bar'baz'         ->   '\''foo!bar'\''baz'\''
		quoted_str="'$quoted_str'"              || return #  '\''foo!bar'\''baz'\''   ->  ''\''foo!bar'\''baz'\'''
		quoted_str="${quoted_str#"''"}"         || return # ''\''foo!bar'\''baz'\'''  ->    \''foo!bar'\''baz'\'''
		quoted_str="${quoted_str%"''"}"         || return #   \''foo!bar'\''baz'\'''  ->    \''foo!bar'\''baz'\'
	elif [[ ! "$str" =~ \' ]]; then
		# as long as a string doesn't contain any single quotation marks, it can be quoted very easily by wrapping it
		# into single quotation marks since they don't support any kind of escape characters

		quoted_str="'$str'" || return
	else
		quoted_str="$str"                   || return
		quoted_str="${quoted_str//\\/\\\\}" || return
		quoted_str="${quoted_str//\$/\\\$}" || return
		quoted_str="${quoted_str//\"/\\\"}" || return
		quoted_str="\"$quoted_str\""        || return
	fi

	readonly quoted_str || return

	#endregion

	printf '%s' "$quoted_str" || return

	if [ -t 1 ]; then
		printf '\n'
	fi
}

command_line="$(pretty_quote "$1")"

declare -i i
for ((i = 1; i < ${#args[@]}; ++i)); do
	command_line+=" $(pretty_quote "${args[i]}")"
done
unset -v i

unset -f pretty_quote

readonly command_line

#endregion

#region command execution

if ! command -v "${args[0]}" > '/dev/null'; then
	printf '%s: %s: command not found\n' "$argv0" "${args[0]}"  >&2
	exit 127
fi


declare -i command_exc

set +o errexit

"${args[@]}"
command_exc=$?

readonly command_exc

#endregion

#region displaying notification

declare -i notify_send_exc
notify_send_exc=0

notify-send --app-name="$1" "Command '$1' Finished" "$ $command_line"
notify_send_exc=$?

readonly notify_send_exc

if [ -t 2 ]; then
	printf '\a' >&2
elif [ -t 1 ]; then
	printf '\a'
fi

#endregion

#region exit code

if [ $command_exc -eq 0 ]; then
	exit $notify_send_exc
fi

exit $command_exc

#endregion
