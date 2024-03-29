# shellcheck shell=bash
# -*- sh -*-
# vim: syntax=bash
# code: language=shellscript

# Copyright (c) 2023 Michael Federczuk
# SPDX-License-Identifier: MPL-2.0 AND Apache-2.0

#region util functions

# these functions are generally only used in other functions
# these kind of functions should have an underscore somewhere in the name

declare TRACE_CMD_DRY_RUN
TRACE_CMD_DRY_RUN='no'
export TRACE_CMD_DRY_RUN

declare -i _TRACE_CMD_LVL
_TRACE_CMD_LVL=0

function is_truthy() {
	#region args

	local str || return

	case $# in
		(0)
			{
				printf '%s: missing argument: <str>\n' "${FUNCNAME[0]}"
				printf 'usage: %s <str>\n' "${FUNCNAME[0]}"
			} >&2
			return 3
			;;
		(1)
			str="$1" || return
			;;
		(*)
			{
				printf '%s: too many arguments: %i\n' "${FUNCNAME[0]}" $(($# - 1))
				printf 'usage: %s <str>\n' "${FUNCNAME[0]}"
			} >&2
			return 4
			;;
	esac

	readonly str || return

	#endregion

	test "${str,,}" = 'true' ||
		[[ "$str" =~ ^['yY'] ]] ||
		{ [[ "$str" =~ ^(+)?[0-9]+$ ]] && ((10#$str > 0)); }
}
complete is_truthy

function readlink_portable() {
	local pathname

	case $# in
		(0)
			{
				printf '%s: missing argument: <symlink>\n' "${FUNCNAME[0]}"
				printf 'usage: %s <symlink>\n' "${FUNCNAME[0]}"
			} >&2
			return 3
			;;
		(1)
			if [ -z "$1" ]; then
				printf '%s: argument must not be empty\n' "${FUNCNAME[0]}" >&2
				return 9
			fi

			pathname="$1"
			;;
		(*)
			{
				printf '%s: too many arguments: %i\n' "${FUNCNAME[0]}" $(($# - 1))
				printf 'usage: %s <symlink>\n' "${FUNCNAME[0]}"
			} >&2
			return 4
			;;
	esac

	readonly pathname


	if [ ! -L "$pathname" ]; then
		printf '%s: %s: not a symlink\n' "${FUNCNAME[0]}" "$pathname" >&2
		return 26
	fi


	# this is rather complicated because POSIX doesn't specifiy a proper utiltiy to read a symlink's target, only `ls`
	# is capable of it

	local ls_out

	ls_out="$(POSIXLY_CORRECT=yes POSIX_ME_HARDER=yes LC_ALL=POSIX LC_CTYPE=POSIX LC_TIME=POSIX ls -dn -- "$pathname" && printf x)"
	ls_out="${ls_out%$'\nx'}"

	# removing <file mode>, <number of links>, <owner name>, <group name>, <size> and <date and time> (where both
	# <owner name> and <group name> are their associated numeric values because of the '-n' option given to `ls`)
	if [[ ! "$ls_out" =~ ^([^[:space:]$' \t']+[[:space:]$' \t']+[0-9]+' '+[0-9]+' '+[0-9]+' '+[0-9]+' '+[A-Za-z]+' '+[0-9]+' '+([0-9]+':'[0-9]+|[0-9]+)' '+"$pathname -> ") ]]; then
		printf '%s: emergency stop: unexpected output of ls\n' "${FUNCNAME[0]}" >&2
		return 123
	fi
	ls_out="${ls_out#"${BASH_REMATCH[1]}"}"

	readonly ls_out


	if [ -t 1 ]; then
		printf '%s\n' "$ls_out"
	else
		printf '%s' "$ls_out"
	fi
}

# normalization is done by squeezing slashes and by removing all unnecessary '.' components
function normalize_pathname() {
	#region args

	local input_pathname || return

	case $# in
		(0)
			{
				printf '%s: missing argument: <pathname>\n' "${FUNCNAME[0]}"
				printf 'usage: %s <pathname>\n' "${FUNCNAME[0]}"
			} >&2
			return 3
			;;
		(1)
			input_pathname="$1" || return
			;;
		(*)
			{
				printf '%s: too many arguments: %i\n' "${FUNCNAME[0]}" $(($# - 1))
				printf 'usage: %s <pathname>\n' "${FUNCNAME[0]}"
			} >&2
			return 4
			;;
	esac

	readonly input_pathname || return

	#endregion

	# if a pathname starts with exactly two consecutive slashes, pathname resolution is implementation-defined so we
	# don't normalize the pathname
	if [[ "$input_pathname" =~ ^'//'([^'/']|$) ]]; then
		printf '%s' "$input_pathname"
		exit
	fi

	#region normalizing the pathname

	local normalized_pathname || return
	normalized_pathname="$input_pathname" || return

	while [[ "$normalized_pathname" =~ '//' ]]; do
		normalized_pathname="${normalized_pathname//'//'/'/'}" || return
	done

	# shellcheck disable=2076
	while [[ "$normalized_pathname" =~ '/./' ]]; do
		normalized_pathname="${normalized_pathname//'/./'/'/'}" || return
	done

	if [[ "$normalized_pathname" =~ ^'./'(.+)$ ]]; then
		normalized_pathname="${BASH_REMATCH[1]}" || return
	fi

	if [[ "$normalized_pathname" =~ ^(.*'/')'.'$ ]]; then
		normalized_pathname="${BASH_REMATCH[1]}" || return
	fi

	readonly normalized_pathname || return

	#endregion

	printf '%s' "$normalized_pathname"
}

function pretty_quote() {
	#region args

	local str

	case $# in
		(0)
			{
				printf '%s: missing argument: <string>\n' "${FUNCNAME[0]}"
				printf 'usage: %s <string>\n' "${FUNCNAME[0]}"
			} >&2
			return 3
			;;
		(1)
			str="$1"
			;;
		(*)
			{
				printf '%s: too many arguments: %i\n' "${FUNCNAME[0]}" $(($# - 1))
				printf 'usage: %s <string>\n' "${FUNCNAME[0]}"
			} >&2
			return 4
			;;
	esac

	readonly str

	#endregion

	#region quoting string

	local quoted_str

	if [[ "$str" =~ ^[A-Za-z0-9_./:+,=-]+$ ]]; then
		# a string that contains only regular characters that don't need escaping or quoting doesn't need to be quoted

		quoted_str="$str"
	elif [[ "$str" =~ '!' ]]; then
		# exclamation marks can't be properly escaped in double quotation marks, which is why we force
		# single quotation marks in that case

		quoted_str="$str"
		quoted_str="${quoted_str//\'/\'\\\'\'}" #     'foo!bar'baz'         ->   '\''foo!bar'\''baz'\''
		quoted_str="'$quoted_str'"              #  '\''foo!bar'\''baz'\''   ->  ''\''foo!bar'\''baz'\'''
		quoted_str="${quoted_str#"''"}"         # ''\''foo!bar'\''baz'\'''  ->    \''foo!bar'\''baz'\'''
		quoted_str="${quoted_str%"''"}"         #   \''foo!bar'\''baz'\'''  ->    \''foo!bar'\''baz'\'
	elif [[ ! "$str" =~ \' ]]; then
		# as long as a string doesn't contain any single quotation marks, it can be quoted very easily by wrapping it
		# into single quotation marks since they don't support any kind of escape characters

		quoted_str="'$str'"
	else
		quoted_str="$str"
		quoted_str="${quoted_str//\\/\\\\}"
		quoted_str="${quoted_str//\$/\\\$}"
		quoted_str="${quoted_str//\"/\\\"}"
		quoted_str="\"$quoted_str\""
	fi

	readonly quoted_str

	#endregion

	printf '%s' "$quoted_str"

	if [ -t 1 ]; then
		printf '\n'
	fi
}
complete pretty_quote

function is_color_supported() {
	#region args

	local fd || return

	case $# in
		(0)
			{
				printf '%s: missing argument: <fd>\n' "${FUNCNAME[0]}"
				printf 'usage: %s <fd>\n' "${FUNCNAME[0]}"
			} >&2
			return 3
			;;
		(1)
			if [ -z "$1" ]; then
				printf '%s: argument must not be empty\n' "${FUNCNAME[0]}" >&2
				return 9
			fi

			fd="$1" || return
			;;
		(*)
			{
				printf '%s: too many arguments: %i\n' "${FUNCNAME[0]}" $(($# - 1))
				printf 'usage: %s <fd>\n' "${FUNCNAME[0]}"
			} >&2
			return 4
			;;
	esac

	readonly fd || return

	#endregion

	if [ -n "${NO_COLOR-}" ] || [ ! -t "$fd" ] || ! command -v tput > '/dev/null'; then
		return 32
	fi

	case "$TERM" in
		('xterm-color'|*'-256color'|'xterm-kitty')
			return 0
			;;
	esac

	if tput 'setaf' '1' >& '/dev/null'; then
		# We have color support; assume it's compliant with Ecma-48 (ISO/IEC-6429).
		# Lack of such support is extremely rare, and such a case would tend to support setf rather than setaf.)
		return 0
	else
		return 32
	fi
}
complete is_color_supported

function trace_cmd() {
	if (($# == 0)); then
		{
			printf '%s: missing arguments: <args>...\n' "${FUNCNAME[0]}"
			printf 'usage: %s [--dry-run] <args>...\n' "${FUNCNAME[0]}"
		} >&2
		return 3
	fi

	#region dry run

	local dry_run || return
	dry_run=false || return

	if [ "$1" = '--dry-run' ]; then
		dry_run=true || return

		shift 1 || return
	fi

	if is_truthy "${TRACE_CMD_DRY_RUN-}"; then
		dry_run=true || return
	fi

	readonly dry_run || return

	#endregion

	#region building pretty args

	local -a pretty_args || return
	pretty_args=() || return

	local arg || return
	for arg in "$@"; do
		local pretty_arg || return
		pretty_arg="$(pretty_quote "$arg" && printf x)" || return
		pretty_arg="${pretty_arg%x}" || return

		pretty_args+=("$pretty_arg") || return

		unset -v pretty_arg || return
	done
	unset -v arg || return

	readonly pretty_args || return

	#endregion

	#region checking for color support

	local color_supported || return
	color_supported=false || return

	if is_color_supported 2; then
		color_supported=true || return
	fi

	readonly color_supported || return

	#endregion

	#region level

	local -i lvl || return
	lvl=0 || return

	if [[ "${_TRACE_CMD_LVL-}" =~ ^('+')?[0-9]+$ ]]; then
		lvl=$((10#$_TRACE_CMD_LVL)) || return
	fi

	readonly lvl || return

	#endregion

	#region printing

	local -i i || return
	for ((i = 0; i < lvl; ++i)); do
		printf '  ' >&2 || return
	done
	unset -v i

	if $color_supported; then
		{ tput bold && tput setaf 4; } >&2 || return
	fi

	{
		printf '$' || return
		printf ' %s' "${pretty_args[@]}" || return
	} >&2

	if $color_supported; then
		tput sgr0 >&2 || return
	fi

	printf '\n' >&2 || return

	#endregion

	local -i exc || return
	exc=0 || return

	if ! $dry_run; then
		_TRACE_CMD_LVL=$((lvl + 1)) "$@"
		exc=$?
	fi

	readonly exc || return $exc

	unset -v _TRACE_CMD_LVL || return $exc
	declare -gi _TRACE_CMD_LVL || return $exc
	_TRACE_CMD_LVL=$((lvl)) || return $exc

	return $exc
}
complete -F _command trace_cmd

function try_as_root() {
	if (($# == 0)); then
		{
			printf '%s: missing arguments: <arg>...\n' "${FUNCNAME[0]}"
			printf 'usage: %s <arg>...\n' "${FUNCNAME[0]}"
		} >&2
		return 3
	fi

	local uid || return
	uid="$(id -u)" || return
	readonly uid || return

	if [ "$uid" != '0' ]; then
		if command -v doas > '/dev/null'; then
			doas "$@"
			return
		fi

		if command -v sudo > '/dev/null'; then
			sudo "$@"
			return
		fi
	fi

	"$@"
}
complete -F _command try_as_root

#endregion

#region sourcing other functions

declare __bash_funcs__func_file_pathname

for __bash_funcs__func_file_pathname in "${XDG_CONFIG_HOME:-"$HOME/.config"}/bash/lib/"*'.bash'; do
	# shellcheck disable=1090
	. "$__bash_funcs__func_file_pathname"
done

unset -v __bash_funcs__func_file_pathname

#endregion
