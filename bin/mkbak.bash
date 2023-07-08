#!/bin/bash
# -*- sh -*-
# vim: set syntax=sh
# code: language=shellscript

# Copyright (c) 2023 Michael Federczuk
# SPDX-License-Identifier: MPL-2.0 AND Apache-2.0

# <https://github.com/mfederczuk/mkbak/releases/tag/v0.1.0-indev01>

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

# Throughout the codebase, the following snippet (or a similiar one) can be found:
#
#         var="$(some_command && printf x)"
#         var="${var%x}"
#
# This is because command substition (this thing --> `$(some_command)`) automatically trims *all* trailing newlines.
# By printing additional non-newline characters (we use the single character 'x' for it) after the command, this
# behavior is avoided because then the newline characters are not anymore the trailing characters.
# Afterwards, the extra trailing 'x' character needs to be removed, which is safe to do so because
# variable substition (this thing --> `${var}`) does not have this trailing-newline-trimming behavior.
#
# A lot of commands (like `basename`, `pwd`, ...) also print an additional newline along the actual data we're
# interested in (e.g.: pathnames printed to stdout), which is why sometimes the second line will look like this:
#
#         var="${var%$'\nx'}"
#
# Which removes the extra newline, but preserves any newlines that belong to the actual data we're interested in.

if [ -z "${BASH_VERSION-}" ]; then
	if [ "${0#/}" = "$0" ]; then # checks whether or not $0 does not start with a slash
		argv0="$0"
	else
		# Rationale as to why only the basename of $0 is used for $argv0 if $0 is an absolute pathname:
		# When an executable file with a shebang is executed via the exec family of functions (which is how shells
		# invoke programs), then the absolute pathname of that file is passed to
		# the (in the shebang defined) interpreter program.
		# So when mkbak is invoked in a shell like this:
		#
		#         $ sh mkbak
		#
		# Then $0 will be an absolute pathname (e.g.: /usr/bin/local/mkbak), but the user doesn't expect error logs to
		# show that absolute pathname --- only the program name --- which is why only the basename is used.

		argv0="$(basename -- "$0" && printf x)"
		argv0="${argv0%"$(printf '\nx')"}"
	fi
	readonly argv0

	printf '%s: GNU Bash is required to execute this script\n' "$argv0" >&2
	exit 1
fi

set -o pipefail
shopt -s nullglob


#region logging

#v#
 # SYNOPSIS:
 #     log [<message>]
 #
 # DESCRIPTION:
 #     Writes the operand <message> to standard error, followed by a newline character.
 #     If the operand <message> is not given, then only the newline charcacter is written.
 #
 # OPERANDS:
 #     <message>  The string to write to standard error.
 #                If this operand is given, it must not be empty.
 #
 # STDERR:
 #     Diagnostic messages in case of an error or --- on success --- the operand <message> (or nothing if it wasn't
 #     given), along with a newline character in the following format:
 #
 #             "%s\n", <message>
 #
 # EXIT STATUS:
 #      0  Success.
 #
 #      4  Too many operands are given.
 #
 #      9  The operand <message> is an empty string.
 #
 #     >0  Another error occurred.
#^#
function log() {
	local message

	case $# in
		(0)
			message=''
			;;
		(1)
			if [ -z "$1" ]; then
				internal_errlog 'argument must not be empty'
				return 9
			fi

			message="$1"
			;;
		(*)
			internal_errlog "too many arguments: $(($# - 1))"
			return 4
			;;
	esac

	readonly message


	printf '%s\n' "$message" >&2
}
readonly -f log

#v#
 # SYNOPSIS:
 #     internal_errlog <message>
 #
 # DESCRIPTION:
 #     Writes a diagnostic message, prefixed by the name of the program (see the function `get_argv0`) and the name of
 #     the function this function was called from, to standard error.
 #
 # OPERANDS:
 #     <message>  The string to write to standard error, it must not be empty.
 #
 # STDERR:
 #     Diagnostic messages in case of an error or --- on success --- the name of the program, the name of the function
 #     this function was called from and the operand <message> in the following format:
 #
 #             "%s: %s: %s\n", <argv0>, <outer_function_name>, <message>
 #
 # EXIT STATUS:
 #      0  Success.
 #
 #      3  The operand <message> is not given.
 #
 #      4  Too many operands are given.
 #
 #      9  The operand <message> is an empty string.
 #
 #     48  This function was not executed from within another function.
 #
 #     >0  Another error occurred.
#^#
function internal_errlog() {
	local message

	case $# in
		(0)
			internal_errlog 'missing argument: <message>'
			return 3
			;;
		(1)
			if [ -z "$1" ]; then
				internal_errlog 'argument must not be empty'
				return 9
			fi

			message="$1"
			;;
		(*)
			internal_errlog "too many arguments: $(($# - 1))"
			return 4
			;;
	esac

	readonly message


	if ((${#FUNCNAME[@]} <= 2)); then
		# shellcheck disable=2016
		internal_errlog 'The function `internal_errlog` must be called from within another function'
		return 48
	fi

	local argv0
	argv0="$(get_argv0 && printf x)"
	argv0="${argv0%x}"
	readonly argv0

	local outer_func_name
	outer_func_name="${FUNCNAME[1]}"
	readonly outer_func_name


	log "$argv0: $outer_func_name: $message"
}
readonly -f internal_errlog

#v#
 # SYNOPSIS:
 #     errlog <message>
 #
 # DESCRIPTION:
 #     Writes a diagnostic message, prefixed by the name of the program (see the function `get_argv0`), to
 #     standard error.
 #
 # OPERANDS:
 #     <message>  The string to write to standard error, it must not be empty.
 #
 # STDERR:
 #     Diagnostic messages in case of an error or --- on success --- the name of the program and the operand <message>
 #     in the following format:
 #
 #             "%s: %s\n", <argv0>, <message>
 #
 # EXIT STATUS:
 #      0  Success.
 #
 #      3  The operand <message> is not given.
 #
 #      4  Too many operands are given.
 #
 #      9  The operand <message> is an empty string.
 #
 #     >0  Another error occurred.
#^#
function errlog() {
	local message

	case $# in
		(0)
			internal_errlog 'missing argument: <message>'
			return 3
			;;
		(1)
			if [ -z "$1" ]; then
				internal_errlog 'argument must not be empty'
				return 9
			fi

			message="$1"
			;;
		(*)
			internal_errlog "too many arguments: $(($# - 1))"
			return 4
			;;
	esac

	readonly message


	local argv0
	argv0="$(get_argv0 && printf x)"
	argv0="${argv0%x}"
	readonly argv0

	log "$argv0: $message"
}
readonly -f errlog

#endregion

#region string utils

# Tests whether or not a string starts with another substring.
#
# $1: base string
# $2: substring
# exit code: 0 if the given base string starts with the given substring, nonzero otherwise
function starts_with() {
	local base_string substring

	case $# in
		(0)
			internal_errlog 'missing arguments: <base_string> <substring>'
			return 3
			;;
		(1)
			internal_errlog 'missing argument: <substring>'
			return 3
			;;
		(2)
			base_string="$1"
			substring="$2"
			;;
		(*)
			internal_errlog "too many arguments: $(($# - 2))"
			return 4
			;;
	esac

	readonly substring base_string


	if [[ "$base_string" =~ ^"$substring" ]]; then
		return 0
	fi

	return 32
}
readonly -f starts_with

# Repeatedly replaces the given search substring with the given replace substring in the given base string, until
# no more instances of the search substring exist.
#
# If the search substring is contained in the replace substring, then this functions fails because otherwise it would
# cause an infinite loop.
#
# $1: base string
# $2: search substring
# $3: replace substring
# stdout: the base string, with all search substrings replaced by the replace substring
function repeat_replace() {
	local base_string search_substring replace_substring

	case $# in
		(0)
			internal_errlog 'missing arguments: <base_string> <search_substring> <replace_substring>'
			return 3
			;;
		(1)
			internal_errlog 'missing arguments: <search_substring> <replace_substring>'
			return 3
			;;
		(2)
			internal_errlog 'missing argument: <replace_substring>'
			return 3
			;;
		(3)
			base_string="$1"
			search_substring="$2"
			replace_substring="$3"
			;;
		(*)
			internal_errlog "too many arguments: $(($# - 3))"
			return 4
			;;
	esac

	readonly replace_substring search_substring base_string


	# shellcheck disable=2076
	if [[ "$replace_substring" =~ "$search_substring" ]]; then
		internal_errlog "refusing to continue because the search substring ($search_substring) is contained in the replace substring ($replace_substring)"
		return 13
	fi


	local replaced_string
	replaced_string="$base_string"

	local repeat
	repeat=true

	while $repeat; do
		local old_replaced_string
		old_replaced_string="$replaced_string"

		replaced_string="${replaced_string//"$search_substring"/"$replace_substring"}"

		if [ "$replaced_string" != "$old_replaced_string" ]; then
			repeat=true
		else
			repeat=false
		fi

		unset -v old_replaced_string
	done

	unset -v repeat

	readonly replaced_string


	printf '%s' "$replaced_string"
}
readonly -f repeat_replace

# Squeezes any and all substrings, which consist of two or more instances of the same given character, into
# a single instance of that character in the given base string.
#
# $1: base string
# $2: character to squeeze
# stdout: the base string, with the given character squeezed
function squeeze() {
	local base_string char

	case $# in
		(0)
			internal_errlog 'missing arguments: <base_string> <char>'
			return 3
			;;
		(1)
			internal_errlog 'missing argument: <char>'
			return 3
			;;
		(2)
			case "$2" in
				('')
					internal_errlog 'argument 2: must not be empty'
					return 9
					;;
				(?)
					# ok
					;;
				(??*)
					internal_errlog "$2: invalid argument: must not be more than one character long"
					return 7
					;;
			esac

			base_string="$1"
			char="$2"
			;;
		(*)
			internal_errlog "too many arguments: $(($# - 2))"
			return 4
			;;
	esac

	readonly char base_string


	repeat_replace "$base_string" "${char}${char}" "$char"
}
readonly -f squeeze

#v#
 # SYNOPSIS:
 #     trim_ws <string>
 #
 # DESCRIPTION:
 #     Trims both leading and trailing whitspace characters of the operand <string> and writes the resulting string to
 #     standard output.
 #
 # OPERANDS:
 #     <string>  String to trim leading and trailing whitespace.
 #
 # STDOUT:
 #     The operand <string> with all leading and trailing whitespace characters trimmed.
 #
 # STDERR:
 #     Diagnostic messages in case of an error.
 #
 # EXIT STATUS:
 #      0  Success.
 #
 #      3  The operand <string> is not given.
 #
 #      4  Too many operands are given.
 #
 #     >0  Another error occurred.
#^#
function trim_ws() {
	local string

	case $# in
		(0)
			internal_errlog 'missing argument: <string>'
			return 3
			;;
		(1)
			string="$1"
			;;
		(*)
			internal_errlog "too many arguments: $(($# - 1))"
			return 4
			;;
	esac

	readonly string


	if [[ "$string" =~ ^[[:space:]]*([^[:space:]]+([[:space:]]+[^[:space:]]+)*)?[[:space:]]*$ ]]; then
		printf '%s' "${BASH_REMATCH[1]}"
		return
	fi

	printf '%s' "$string"
}
readonly -f trim_ws

#endregion


#v#
 # SYNOPSIS:
 #     command_exists <command_name>
 #
 # DESCRIPTION:
 #     Indicates whether or not the command with the name of the operand <command_name> exists.
 #
 # OPERANDS:
 #     <command_name>  The name of a command.
 #
 # STDERR:
 #     Diagnostic messages in case of an error.
 #
 # EXIT STATUS:
 #      0  Success, the command exists.
 #
 #      3  The operand <command_name> is not given.
 #
 #      4  Too many operands are given.
 #
 #     >0  The command does not exist or another error occurred.
#^#
function command_exists() {
	local command_name

	case $# in
		(0)
			internal_errlog 'missing argument: <command_name>'
			return 3
			;;
		(1)
			if [ -z "$1" ]; then
				internal_errlog 'argument must not be empty'
				return 9
			fi

			command_name="$1"
			;;
		(*)
			internal_errlog "too many arguments: $(($# - 1))"
			return 4
			;;
	esac

	readonly command_name


	command -v "$command_name" > '/dev/null'
}
readonly -f command_exists


#region pathname utils

# Writes the current working directory to standard output.
#
# stdout: the current working directory
# <https://github.com/koalaman/shellcheck/issues/2492>
# shellcheck disable=2120
function get_cwd() {
	if (($# > 0)); then
		internal_errlog "too many arguments: $#"
		return 4
	fi


	local cwd
	cwd="$(pwd -L && printf x)"
	cwd="${cwd%$'\nx'}"
	readonly cwd

	printf '%s' "$cwd"
}
readonly -f get_cwd

#v#
 # SYNOPSIS:
 #     ensure_absolute_pathname <pathname>
 #
 # DESCRIPTION:
 #     Ensures that the operand <pathname> is an absolute pathname by prefixing it with the current working directory
 #     if it is a relative pathname. (see the function `get_cwd`)
 #
 # OPERANDS:
 #     <pathname>  The pathname to turn absolute (if it is not already).
 #
 # STDOUT:
 #     The operand <pathname>, ensured to be an absolute pathname.
 #
 # STDERR:
 #     Diagnostic messages in case of an error.
 #
 # EXIT STATUS:
 #      0  Success.
 #
 #      3  The operand <pathname> is not given.
 #
 #      4  Too many operands are given.
 #
 #     >0  Another error occurred.
#^#
function ensure_absolute_pathname() {
	local pathname

	case $# in
		(0)
			internal_errlog 'missing argument: <pathname>'
			return 3
			;;
		(1)
			if [ -z "$1" ]; then
				internal_errlog 'argument must not be empty'
				return 9
			fi

			pathname="$1"
			;;
		(*)
			internal_errlog "too many arguments: $(($# - 1))"
			return 4
			;;
	esac

	readonly pathname


	local absolute_pathname

	if starts_with "$pathname" '/'; then
		absolute_pathname="$pathname"
	else
		local cwd
		cwd="$(get_cwd && printf x)"
		cwd="${cwd%x}"

		absolute_pathname="$cwd/$pathname"

		unset -v cwd
	fi

	readonly absolute_pathname


	normalize_pathname "$absolute_pathname"
}
readonly -f ensure_absolute_pathname

# Reads the contents of a symbolic link and writes it to standard output.
#
# $1: pathname of the symlink
# stdout: contents of the given symlink
function readlink_portable() {
	local pathname

	case $# in
		(0)
			internal_errlog 'missing argument: <symlink>'
			return 3
			;;
		(1)
			if [ -z "$1" ]; then
				internal_errlog 'argument must not be empty'
				return 9
			fi

			pathname="$1"
			;;
		(*)
			internal_errlog "too many arguments: $(($# - 1))"
			return 4
			;;
	esac

	readonly pathname


	if [ ! -L "$pathname" ]; then
		internal_errlog "$pathname: not a symlink"
		return 26
	fi


	# this is rather complicated because POSIX doesn't specifiy a proper utiltiy to read a symlink's target, only `ls`
	# is capable of it

	local ls_out

	ls_out="$(LC_ALL=POSIX LC_CTYPE=POSIX LC_TIME=POSIX ls -dn -- "$pathname" && printf x)"
	ls_out="${ls_out%$'\nx'}"

	# removing <file mode>, <number of links>, <owner name>, <group name>, <size> and <date and time> (where both
	# <owner name> and <group name> are their associated numeric values because of the '-n' option given to `ls`)
	if [[ ! "$ls_out" =~ ^([^[:space:]$' \t']+[[:space:]$' \t']+[0-9]+' '+[0-9]+' '+[0-9]+' '+[0-9]+' '+[A-Za-z]+' '+[0-9]+' '+([0-9]+':'[0-9]+|[0-9]+)' '+"$pathname -> ") ]]; then
		internal_errlog 'emergency stop: unexpected output of ls'
		return 123
	fi
	ls_out="${ls_out#"${BASH_REMATCH[1]}"}"

	readonly ls_out


	printf '%s' "$ls_out"
}
readonly -f readlink_portable

# Normalizes the given pathname and writes it to the standard output.
#
# Normalization is done by squeezing multiple slashes into one and by removing all unnecessary '.' pathname components.
#
# If the given pathname is empty, nothing / the same empty pathname is written to the standard output.
#
# $1: the pathname to normalize
# stdout: the normalized pathname, or nothing if the given argument is empty
function normalize_pathname() {
	local pathname

	case $# in
		(0)
			internal_errlog 'missing argument: <pathname>'
			return 3
			;;
		(1)
			pathname="$1"
			;;
		(*)
			internal_errlog "too many arguments: $(($# - 1))"
			return 4
			;;
	esac

	readonly pathname


	if [ -z "$pathname" ]; then
		return 0
	fi


	local normalized_pathname
	normalized_pathname="$pathname"

	normalized_pathname="$(squeeze "$normalized_pathname" '/' && printf x)"
	normalized_pathname="${normalized_pathname%x}"

	normalized_pathname="$(repeat_replace "$normalized_pathname" '/./' '/' && printf x)"
	normalized_pathname="${normalized_pathname%x}"

	if [[ "$normalized_pathname" =~ ^'./'(.+)$ ]]; then
		normalized_pathname="${BASH_REMATCH[1]}"
	fi

	if [[ "$normalized_pathname" =~ ^(.*'/')'.'$ ]]; then
		normalized_pathname="${BASH_REMATCH[1]}"
	fi

	readonly normalized_pathname


	printf '%s' "$normalized_pathname"
}
readonly -f normalize_pathname

#v#
 # SYNOPSIS:
 #     resolve_pathname <pathname>
 #
 # DESCRIPTION:
 #     Implements Linux path resolution (see Linux man page path_resolution(7)) and writes the results to
 #     standard output.
 #
 # OPERANDS:
 #     <pathname>  Pathname to resolve.
 #
 # STDOUT:
 #     The results of
 #
 #             "%s:%s", <result_type>, <result_pathname>
 #
 #     The result type is one of the following strings:
 #
 #         unknown    Succesful resolution. The result pathname may not exist, be a directory or be a any type of file.
 #                    Read and/or write access may not be given to the result pathname or its parent directory.
 #
 #         directory  Succesful resolution. The result pathname is an existing directory.
 #                    Read and/or write access may not be given to the result pathname or its parent directory.
 #
 #         EACCESS    Failed resolution. Search permissions are missing on the result pathname. It is NOT same pathname
 #                    pointed to by the operand <pathname>.
 #
 #         ENOENT     Failed resolution. The result pathname does not exist. It is NOT same pathname pointed to by
 #                    the operand <pathname>.
 #
 #         ENOTDIR    Failed resolution. The result pathname is not a directory. It may or may not be the same pathname
 #                    pointed to by the operand <pathname>.
 #
 # STDERR:
 #     Diagnostic messages in case of an error.
 #
 # EXIT STATUS:
 #      0  Success.
 #
 #      3  The operand <pathname> is not given.
 #
 #      4  Too many operands are given.
 #
 #     >0  Another error occurred.
#^#
function resolve_pathname() {
	local pathname

	case $# in
		(0)
			internal_errlog 'missing argument: <pathname>'
			return 3
			;;
		(1)
			pathname="$1"
			;;
		(*)
			internal_errlog "too many arguments: $(($# - 1)))"
			return 4
			;;
	esac

	pathname="$(normalize_pathname "$pathname" && printf x)"
	pathname="${pathname%x}"

	readonly pathname


	case "$pathname" in
		('')
			printf 'ENOENT:'
			return
			;;
		('/')
			printf 'directory:/'
			return
			;;
	esac


	local force_final_component_directory
	force_final_component_directory=false

	if [[ "$pathname" =~ '/'$ ]]; then
		force_final_component_directory=true
	fi

	readonly force_final_component_directory


	local starting_lookup_directory
	if starts_with "$pathname" '/'; then
		starting_lookup_directory='/'
	else
		starting_lookup_directory='.'
	fi
	readonly starting_lookup_directory


	local -a pathname_components
	pathname_components=()

	local current_component
	current_component=''

	local -i i
	for ((i = 0; i < ${#pathname}; ++i)); do
		local ch
		ch="${pathname:i:1}"

		if [ "$ch" != '/' ]; then
			current_component+="$ch"
		elif [ -n "$current_component" ]; then
			pathname_components+=("$current_component")
			current_component=''
		fi

		unset -v ch
	done
	unset -v i

	if [ -n "$current_component" ]; then
		pathname_components+=("$current_component")
	fi

	unset -v current_component

	readonly pathname_components


	local current_lookup_directory
	current_lookup_directory="$starting_lookup_directory"

	local -i i

	for ((i = 0; i < ${#pathname_components[@]}; ++i)); do
		local component
		component="${pathname_components[i]}"

		if [ ! -x "$current_lookup_directory" ]; then
			printf 'EACCESS:%s' "$current_lookup_directory"
			return
		fi

		local entry_pathname
		case "$current_lookup_directory" in
			('/') entry_pathname="/$component" ;;
			('.') entry_pathname="$component"  ;;
			(*)   entry_pathname="$current_lookup_directory/$component" ;;
		esac

		if [ -L "$entry_pathname" ]; then
			local target_pathname
			target_pathname="$(readlink_portable "$entry_pathname" && printf x)"
			target_pathname="${target_pathname%x}"

			if ! starts_with "$target_pathname" '/'; then
				target_pathname="$current_lookup_directory/$target_pathname"
			fi

			result="$(resolve_pathname "$target_pathname" && printf x)"
			result="${result%x}"

			if [[ ! "$result" =~ ^[a-z]+':'(.+)$ ]]; then
				printf '%s' "$result"
				return
			fi

			entry_pathname="${BASH_REMATCH[1]}"

			unset -v result target_pathname
		fi

		if (((i + 1) >= ${#pathname_components[@]})); then
			local result
			result='unknown'

			if $force_final_component_directory; then
				if [ -d "$entry_pathname" ]; then
					result='directory'
				else
					result='ENOTDIR'
				fi
			fi

			printf '%s:%s' "$result" "$entry_pathname"

			return
		fi

		if [ ! -e "$entry_pathname" ]; then
			printf 'ENOENT:%s' "$entry_pathname"
			return
		fi

		if [ ! -d "$entry_pathname" ]; then
			printf 'ENOTDIR:%s' "$entry_pathname"
			return
		fi

		current_lookup_directory="$entry_pathname"

		unset -v entry_pathname component
	done

	internal_errlog "unknown error: we shouldn't be here :("
	return 125
}
readonly -f resolve_pathname

#endregion


# Writes the basename or relative pathname of this script file to the standard output.
#
# If $0 is an absolute pathname, only the basename of that pathname is written to the standard output,
# otherwise (if $0 is a relative pathname) $0 will be normalized (see the function `normalize_pathname`) and then
# written to the standard output.
#
# Rationale as to why only the basename of $0 is written to the standard output if it is an absolute pathname:
# When an executable file with a shebang is executed via the exec family of functions (which is how shells
# invoke programs), then the absolute pathname of that file is passed to
# the (in the shebang defined) interpreter program.
# So when mkbak is invoked in a shell simply like this:
#
#         $ mkbak
#
# Then $0 will be an absolute pathname (e.g.: /usr/bin/local/mkbak), but the user doesn't expect error logs to show
# that absolute pathname --- only the program name --- which is why only the basename is written.
#
# stdout: the name of this script file
# <https://github.com/koalaman/shellcheck/issues/2492>
# shellcheck disable=2120
function get_argv0() {
	if (($# > 0)); then
		internal_errlog "too many arguments: $#"
		return 4
	fi


	if starts_with "$0" '/'; then
		local basename
		basename="$(basename -- "$0" && printf x)"
		basename="${basename%$'\nx'}"
		readonly basename

		printf '%s' "$basename"

		return
	fi


	local starts_with_dot
	starts_with_dot=false

	if starts_with "$0" './'; then
		starts_with_dot=true
	fi

	readonly starts_with_dot


	local pathname

	pathname="$(normalize_pathname "$0" && printf x)"
	pathname="${pathname%x}"

	if $starts_with_dot; then
		pathname="./$pathname"
	fi

	readonly pathname


	printf '%s' "$pathname"
}
readonly -f get_argv0


#v#
 # SYNOPSIS:
 #     escape_glob_pattern <glob_pattern>
 #
 # DESCRIPTION:
 #     Escapes the glob pattern operand <glob_pattern> and writes it to standard output.
 #
 # OPERANDS:
 #     <glob_pattern>  The glob pattern to escape.
 #
 # STDOUT:
 #     The escaped glob pattern.
 #
 # STDERR:
 #     Diagnostic messages in case of an error.
 #
 # EXIT STATUS:
 #      0  Success.
 #
 #      3  The operand <string> is not given.
 #
 #      4  Too many operands are given.
 #
 #     >0  Another error occurred.
 #
 # SEE ALSO:
 #     glob(7)
#^#
function escape_glob_pattern() {
	local glob_pattern

	case $# in
		(0)
			internal_errlog 'missing argument: <glob_pattern>'
			return 3
			;;
		(1)
			glob_pattern="$1"
			;;
		(*)
			internal_errlog "too many arguments: $(($# - 1))"
			return 4
			;;
	esac

	readonly glob_pattern


	local escaped_glob_pattern
	escaped_glob_pattern="$glob_pattern"

	escaped_glob_pattern="${escaped_glob_pattern//'?'/'\?'}"
	escaped_glob_pattern="${escaped_glob_pattern//'*'/'\*'}"
	escaped_glob_pattern="${escaped_glob_pattern//'['/'\['}"

	readonly escaped_glob_pattern


	printf '%s' "$escaped_glob_pattern"
}
readonly -f escape_glob_pattern


# Prints a given message to standard error and then prompts the user for a boolean yes/no answer.
# The given message should end with a question mark but should not contain any trailing whitespace or an "input hint"
# that most of the time takes a form of "(y/n)", "[Y/n]" or "[y/N]" as it will be added automatically.
#
# $1: message
# $2: default answer, must be 'default=yes' or 'default=no'
# exit code: zero if the answer was yes, 32 if the answer was no
function prompt_yes_no() {
	local message default_is_yes

	case $# in
		(0)
			internal_errlog 'missing arguments: <message> default=(yes|no)'
			return 3
			;;
		(1)
			internal_errlog 'missing argument: default=(yes|no)'
			return 3
			;;
		(2)
			message="$1"

			case "$2" in
				('default=yes') default_is_yes=true  ;;
				('default=no')  default_is_yes=false ;;
				(*)
					internal_errlog "$2: invalid argument: must be either 'default=yes' or 'default=yes'"
					return 7
					;;
			esac
			;;
		(*)
			internal_errlog "too many arguments: $(($# - 2))"
			return 4
			;;
	esac

	readonly default_is_yes message


	local y n
	if $default_is_yes; then
		y='Y'
		n='n'
	else
		y='y'
		n='N'
	fi

	printf '%s [%s/%s] ' "$message" "$y" "$n" >&2

	unset -v n y


	local ans
	read -r ans

	if [ -z "$ans" ]; then
		if $default_is_yes; then
			ans='y'
		else
			ans='n'
		fi
	fi

	if [[ "$ans" =~ ^['yY'] ]]; then
		return 0
	fi

	return 32
}
readonly -f prompt_yes_no


readonly mkbak_version_major=0
readonly mkbak_version_minor=1
readonly mkbak_version_patch=0
readonly mkbak_version_pre_release='indev01'

declare mkbak_version="$mkbak_version_major.$mkbak_version_minor.$mkbak_version_patch"
if [ -n "$mkbak_version_pre_release" ]; then
	mkbak_version+="-$mkbak_version_pre_release"
fi
readonly mkbak_version



readonly exc_usage_argument_must_be_absolute_pathname=13 \
         exc_usage_argument_must_not_end_with_slash=14 \
         exc_usage_output_filename_must_be_non_empty_gzipped_tarball=15

readonly exc_feedback_prompt_abort=32

readonly exc_error_env_var_must_not_be_unset_or_empty=48 \
         exc_error_env_var_must_be_absolute_pathname=49 \
         exc_error_gnu_tar_required=50 \
         exc_error_input_file_malformed=51 \
         exc_error_no_bak_pathnames=52


function usage_errlog() {
	local message

	case $# in
		(0)
			internal_errlog 'missing argument: <message>'
			return 3
			;;
		(1)
			if [ -z "$1" ]; then
				internal_errlog 'argument must not be empty'
				return 9
			fi

			message="$1"
			;;
		(*)
			internal_errlog "too many arguments: $(($# - 1))"
			return 4
			;;
	esac

	readonly message


	local argv0
	argv0="$(get_argv0 && printf x)"
	argv0="${argv0%x}"
	readonly argv0


	local usage
	usage="$(cat <<EOF
usage: $argv0 [-N] [-i <file>] [-o <file>] [(-p <dest>)...] [<path>...]
EOF
)"
	readonly usage


	errlog "$message"
	log "$usage"
}
readonly -f usage_errlog



declare -a _cli_options_short_chars=()
declare -a _cli_options_long_ids=()
declare -a _cli_options_arg_specs=()
declare -a _cli_options_prios=()
declare -a _cli_options_cmds=()

# $1: short character (must start with '-') or an empty string if the option doesn't have a short character
# $2: long identifier (must start with '--')
# $3: either 'no_arg', 'arg_required:<arg_name>' or 'arg_optional:<arg_name>'
# $4: either 'low_prio' or 'high_prio'
# $5: handling command; command to execute when the option is specified on the command line
function cli_options_define() {
	local short_char long_id arg_spec prio cmd

	case $# in
		(0)
			internal_errlog 'missing arguments: ( -<short_char> | "") --<long_id> <arg_spec> <priority> <command>'
			return 3
			;;
		(1)
			internal_errlog 'missing arguments: --<long_id> <arg_spec> <priority> <command>'
			return 3
			;;
		(2)
			internal_errlog 'missing arguments: <arg_spec> <priority> <command>'
			return 3
			;;
		(3)
			internal_errlog 'missing arguments: <priority> <command>'
			return 3
			;;
		(4)
			internal_errlog 'missing arguments: <command>'
			return 3
			;;
		(5)
			short_char="$1"
			long_id="$2"
			arg_spec="$3"
			prio="$4"
			cmd="$5"
			;;
		(*)
			internal_errlog "too many arguments: $(($# - 5))"
			return 4
			;;
	esac

	if [ -n "$short_char" ]; then
		if [[ "$short_char" =~ ^'-'(.)$ ]]; then
			short_char="${BASH_REMATCH[1]}"
		else
			internal_errlog "$short_char: does not match: /^-.$/"
			return 12
		fi
	fi
	readonly short_char

	if [[ "$long_id" =~ ^'--'([^'=']+)$ ]]; then
		long_id="${BASH_REMATCH[1]}"
	else
		internal_errlog "$long_id: does not match: /^--[^=]+$/"
		return 12
	fi
	readonly long_id

	case "$arg_spec" in
		('no_arg')
			arg_spec='none:'
			;;
		('arg_required:'?*)
			arg_spec="required:${arg_spec#arg_required:}"
			;;
		('arg_optional:'?*)
			arg_spec="optional:${arg_spec#arg_optional:}"
			;;
		(*)
			internal_errlog "$arg_spec: must be either 'no_arg', 'arg_required:<arg_name>' or 'arg_optional:<arg_name>'"
			return 13
			;;
	esac
	readonly arg_spec

	case "$prio" in
		('low_prio'|'high_prio')
			# ok
			;;
		(*)
			internal_errlog "$prio: must be either 'low_prio' or 'high_prio'"
			return 14
			;;
	esac
	readonly prio="${prio%_prio}"

	readonly cmd
	if [ -z "$cmd" ]; then
		internal_errlog 'argument 5: must not be empty'
		return 9
	fi
	if ! command_exists "$cmd"; then
		internal_errlog "$cmd: no such command"
		return 24
	fi


	_cli_options_short_chars+=("$short_char")
	_cli_options_long_ids+=("$long_id")
	_cli_options_arg_specs+=("$arg_spec")
	_cli_options_prios+=("$prio")
	_cli_options_cmds+=("$cmd")
}
readonly -f cli_options_define

# $1: short char to search for
# stdout: handle to access the options's details or nothing if no option was found
function cli_options_find_by_short_char() {
	local requested_char
	case $# in
		(0)
			internal_errlog 'missing argument: <short_char>'
			return 3
			;;
		(1)
			requested_char="$1"
			;;
		(*)
			internal_errlog "too many arguments: $(($# - 1))"
			return 4
			;;
	esac
	readonly requested_char

	if ((${#requested_char} != 1)); then
		internal_errlog "$requested_char: must be a single character"
		return 13
	fi

	local -i i
	for ((i = 0; i < ${#_cli_options_short_chars[@]}; ++i)); do
		if [ "${_cli_options_short_chars[i]}" = "$requested_char" ]; then
			printf '%d' "$i"
			exit 0
		fi
	done
}
readonly -f cli_options_find_by_short_char

# $1: long identifier to search for
# stdout: handle to access the options's details or nothing if no option was found
function cli_options_find_by_long_id() {
	local requested_id
	case $# in
		(0)
			internal_errlog 'missing argument: <long_identifier>'
			return 3
			;;
		(1)
			requested_id="$1"
			;;
		(*)
			internal_errlog "too many arguments: $(($# - 1))"
			return 4
			;;
	esac
	readonly requested_id

	if [ -z "$requested_id" ]; then
		internal_errlog 'argument must not be empty'
		return 9
	fi
	if [[ "$requested_id" =~ '=' ]]; then
		internal_errlog "$requested_id: must not contain a equals character ('=')"
		return 13
	fi

	local -i i
	for ((i = 0; i < ${#_cli_options_long_ids[@]}; ++i)); do
		if [ "${_cli_options_long_ids[i]}" = "$requested_id" ]; then
			printf '%d' "$i"
			exit 0
		fi
	done
}
readonly -f cli_options_find_by_long_id

function cli_options_is_handle_valid() {
	local handle
	case $# in
		(0)
			internal_errlog 'missing argument: <handle>'
			return 3
			;;
		(1)
			handle="$1"
			;;
		(*)
			internal_errlog "too many arguments: $(($# - 1))"
			return 4
			;;
	esac
	readonly handle

	[[ "$handle" =~ ^('0'|[1-9][0-9]*)$ ]]
}
readonly -f cli_options_is_handle_valid

# $1: option handle
# exit code: zero if the option requires an argument, nonzero otherwise or the option with the given handle exists
function cli_options_option_requires_arg() {
	local handle
	case $# in
		(0)
			internal_errlog 'missing argument: <handle>'
			return 3
			;;
		(1)
			handle="$1"
			;;
		(*)
			internal_errlog "too many arguments: $(($# - 1))"
			return 4
			;;
	esac
	readonly handle

	if [ -z "$handle" ]; then
		internal_errlog 'argument must not be empty'
		return 9
	fi
	if ! cli_options_is_handle_valid "$handle"; then
		internal_errlog 'given handle is not valid'
		return 13
	fi

	if ((handle >= ${#_cli_options_arg_specs[@]})); then
		return 32
	fi

	local -r arg_spec="${_cli_options_arg_specs[handle]}"

	case "$arg_spec" in
		('none:'|'optional:'*)
			return 33
			;;
		('required:'*)
			return 0
			;;
	esac
}
readonly -f cli_options_option_requires_arg

# $1: option handle
# exit code: zero if the option is high priority, nonzero otherwise or the option with the given handle exists
function cli_options_option_is_high_prio() {
	local handle
	case $# in
		(0)
			internal_errlog 'missing argument: <handle>'
			return 3
			;;
		(1)
			handle="$1"
			;;
		(*)
			internal_errlog "too many arguments: $(($# - 1))"
			return 4
			;;
	esac
	readonly handle

	if [ -z "$handle" ]; then
		internal_errlog 'argument must not be empty'
		return 9
	fi
	if ! cli_options_is_handle_valid "$handle"; then
		internal_errlog 'given handle is not valid'
		return 13
	fi

	if ((handle >= ${#_cli_options_prios[@]})); then
		return 32
	fi

	local -r prio="${_cli_options_prios[handle]}"

	test "$prio" = 'high' || return 33
}
readonly -f cli_options_option_is_high_prio

# $1: option handle
# $2: origin
# $@: arguments to pass to the option's handling command; must not be more than one
function cli_options_execute() {
	local handle origin
	local -a args_to_pass=()
	case $# in
		(0)
			internal_errlog 'missing arguments: <handle> <origin> [<arg>]'
			return 3
			;;
		(1)
			internal_errlog 'missing arguments: <origin> [<arg>]'
			return 3
			;;
		(3)
			args_to_pass+=("$3")
			;&
		(2)
			handle="$1"
			origin="$2"
			;;
		(*)
			internal_errlog "too many arguments: $(($# - 3))"
			return 4
			;;
	esac
	readonly args_to_pass origin handle

	if [ -z "$handle" ]; then
		internal_errlog 'argument 1: must not be empty'
		return 9
	fi
	if ! cli_options_is_handle_valid "$handle"; then
		internal_errlog 'given handle is not valid'
		return 13
	fi

	if [ -z "$origin" ]; then
		internal_errlog 'argument 2: must not be empty'
		return 9
	fi
	if [[ ! "$origin" =~ ^('-'.|'--'[^'=']+)$ ]]; then
		internal_errlog "$origin: does not match /^(-.|--[^=]+)$/"
		return 12
	fi

	if ((handle >= ${#_cli_options_arg_specs[@]} || handle >= ${#_cli_options_cmds[@]})); then
		internal_errlog 'option with the given handle does not exist'
		return 48
	fi

	local -r arg_spec="${_cli_options_arg_specs[handle]}"

	case "$arg_spec" in
		('none:')
			if ((${#args_to_pass[@]} > 0)); then
				usage_errlog "$origin: too many arguments: ${#args_to_pass[@]}"
				return 4
			fi
			;;
		('required:'?*)
			if ((${#args_to_pass[@]} == 0)); then
				usage_errlog "$origin: missing argument: <${arg_spec#required:}>"
				return 3
			fi
			;;
		('optional:'?*)
			# ok
			;;
		(*)
			internal_errlog "emergency stop: arg_spec of option with handle of '$handle' is invalid ($arg_spec)"
			return 123
			;;
	esac

	local argv0
	argv0="$(get_argv0 && printf x)"
	argv0="${argv0%x}"
	readonly argv0

	local -r cmd="${_cli_options_cmds[handle]}"

	"$cmd" "$origin" "$argv0" "${args_to_pass[@]}"
}
readonly -f cli_options_execute



# either 'default:', 'file:...' or 'stdin:'
declare bak_pathnames_input_source='default:'

function cli_opt_input() {
	local -r origin="$1"
	local pathname="$3"

	case "$pathname" in
		('')
			errlog "$origin: argument must not be empty"
			return 9
			;;
		('-')
			bak_pathnames_input_source='stdin:'
			;;
		(*)
			pathname="$(normalize_pathname "$pathname" && printf x)"
			pathname="${pathname%x}"

			bak_pathnames_input_source="file:$pathname"
			;;
	esac
}
readonly -f cli_opt_input

cli_options_define '-i' '--input' 'arg_required:file' \
                   'low_prio' cli_opt_input


# either 'file:...' or 'stdout:'
declare output_archive_target
output_archive_target="file:$(date +'%Y-%m-%d').tar.gz"

function cli_opt_output() {
	local -r origin="$1"
	local pathname="$3"

	case "$pathname" in
		('')
			errlog "$origin: argument must not be empty"
			return 9
			;;
		('-')
			output_archive_target='stdout:'
			;;
		(*'/')
			errlog "$origin: $pathname: argument must not end with a slash"
			return $exc_usage_argument_must_not_end_with_slash
			;;
		(*)
			pathname="$(normalize_pathname "$pathname" && printf x)"
			pathname="${pathname%x}"

			local basename
			basename="$(basename -- "$pathname" && printf x)"
			basename="${basename%$'\nx'}"

			if [[ ! "$basename" =~ .+('.tar.gz'|'.tgz')$ ]]; then
				if [[ "$basename" =~ ^('.tar.gz'|'.tgz')$ ]]; then
					errlog "$origin: $pathname: filename without prefix '.tar.gz'/'.tgz' must not be empty"
				else
					errlog "$origin: $pathname: filename must end with '.tar.gz' and '.tgz'"
				fi

				return $exc_usage_output_filename_must_be_non_empty_gzipped_tarball
			fi

			unset -v basename

			output_archive_target="file:$pathname"
			;;
	esac
}
readonly -f cli_opt_output

cli_options_define '-o' '--output' 'arg_required:archive' \
                   'low_prio' cli_opt_output


declare include_user_crontab=true


function cli_opt_crontab() {
	include_user_crontab=true
}

cli_options_define '-n' '--crontab' 'no_arg' \
                   'low_prio' cli_opt_crontab


function cli_opt_no_crontab() {
	include_user_crontab=false
}
readonly -f cli_opt_no_crontab

cli_options_define '-N' '--no-crontab' 'no_arg' \
                   'low_prio' cli_opt_no_crontab


declare -a copy_destination_pathnames=()

function cli_opt_copy() {
	local -r origin="$1"
	local pathname="$3"

	if [ -z "$pathname" ]; then
		errlog "$origin: argument must not be empty"
		return 9
	fi

	pathname="$(normalize_pathname "$pathname" && printf x)"
	pathname="${pathname%x}"

	readonly pathname

	# avoid adding the same pathname twice
	local copy_destination_pathname
	for copy_destination_pathname in "${copy_destination_pathnames[@]}"; do
		if [ "$copy_destination_pathname" = "$pathname" ]; then
			return 0
		fi
	done

	copy_destination_pathnames+=("$pathname")
}
readonly -f cli_opt_copy

cli_options_define '-p' '--copy' 'arg_required:dest' \
                   'low_prio' cli_opt_copy



function cli_opt_help() {
	local -r argv0="$2"

	local help_message
	help_message="$(cat <<EOF
usage: $argv0 [-N] [-i <file>] [-o <file>] [(-p <dest>)...] [<path>...]
    Creates a gzipped tarball archive containing the given PATHs.
    Contents of directories are included recursively.

    If a directory contains a '.nobak' file, the contents of that directory will be excluded, except when explicitly
    added.
    If a directory contains a '.nobakpattern' file, the patterns to exclude relative to that directory are read from
    this file. Patterns are separated by newlines.

    When no PATHs were given and neither the --input nor the --crontab options were specified, the default input file
    will be used that is specified in the config file.
    When no default input file is configured, the program will fail.

    Options:
      -i, --input=<file>      Read paths to archive from FILE. Paths are separated with newlines.
                              When FILE is '-', read from stdin.

      -o, --output=<file>     Write archive to FILE.
                              When FILE is '-', write to stdout.
                              Default is '<year>-<month>-<day>.tar.gz'.

      -n, --crontab           Also archive the user's crontab. (default)
      -N, --no-crontab        Don't archive the user's crontab.

      -p, --copy=<dest>       Copy archive to DEST. DEST can be either a directory or file.
                              This option can be specified multiple times.
                              When the --output option is specified as '-' all --copy options are ignored.

      -h, --help              Show this summary and exit successfully.
      -V, --version           Show version and legal information and exit successfully.

    Config:
      The mkbak config file is located at '\$XDG_CONFIG_HOME/mkbak/mkbak.conf'.
      It's simple key-value dictionary storage using the equals character ('=') as the key-value separator.
      The following keys are recognized:

        default_input_file_path (string/path)
            The default input file to use when otherwise no paths to archive are given.

GitHub Repository: <https://github.com/mfederczuk/mkbak>
EOF
)"
	readonly help_message

	log "$help_message"
}
readonly -f cli_opt_help

cli_options_define '-h' '--help' 'no_arg' \
                   'high_prio' cli_opt_help


function cli_opt_version_info() {
	local version_info_message
	version_info_message="$(cat <<EOF
mkbak $mkbak_version

Copyright (C) 2023 Michael Federczuk

    License MPL-2.0: Mozilla Public License 2.0 <https://www.mozilla.org/en-US/MPL/2.0/>
            AND
    License Apache-2.0: Apache License 2.0 <https://www.apache.org/licenses/LICENSE-2.0>

This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
EOF
)"
	readonly version_info_message

	log "$version_info_message"
}
readonly -f cli_opt_version_info

cli_options_define '-V' '--version' 'no_arg' \
                   'high_prio' cli_opt_version_info

declare -a bak_pathnames=()

declare -a cli_option_low_prio_handles=()
declare -a cli_option_low_prio_origins=()
declare -a cli_option_low_prio_args=()

declare cli_first_invalid_opt=''

declare cli_option_high_prio_handle=''
declare cli_option_high_prio_origin
declare cli_option_high_prio_arg='none:'

declare -a cli_args=("$@")
declare -i cli_arg_i
declare cli_process_opts=true

for ((cli_arg_i = 0; cli_arg_i < $#; ++cli_arg_i)); do
	declare arg="${cli_args[cli_arg_i]}"

	if $cli_process_opts; then
		if [ "$arg" = '--' ]; then
			cli_process_opts=false
			continue
		fi

		if [[ "$arg" =~ ^'--'([^'=']+)('='(.*))?$ ]]; then
			declare opt_id="${BASH_REMATCH[1]}"

			declare opt_handle
			opt_handle="$(cli_options_find_by_long_id "$opt_id")"

			if [ -n "$opt_handle" ]; then
				declare opt_arg='none:'
				if [ -n "${BASH_REMATCH[2]}" ]; then
					opt_arg="present:${BASH_REMATCH[3]}"
				fi

				if [ "$opt_arg" = 'none:' ] &&
				   cli_options_option_requires_arg "$opt_handle" &&
				   (((cli_arg_i + 1) < $#)); then

					((++cli_arg_i))
					opt_arg="present:${cli_args[cli_arg_i]}"
				fi

				if cli_options_option_is_high_prio "$opt_handle"; then
					if [ -z "$cli_option_high_prio_handle" ]; then
						cli_option_high_prio_handle="$opt_handle"
						cli_option_high_prio_origin="--$opt_id"
						cli_option_high_prio_arg="$opt_arg"
					fi
				else
					cli_option_low_prio_handles+=("$opt_handle")
					cli_option_low_prio_origins+=("--$opt_id")
					cli_option_low_prio_args+=("$opt_arg")
				fi

				unset -v opt_arg
			elif [ -z "$cli_first_invalid_opt" ]; then
				cli_first_invalid_opt="--$opt_id"
			fi

			unset -v opt_handle opt_id

			continue
		fi

		if [[ "$arg" =~ ^'-'(.+)$ ]]; then
			declare opt_chars="${BASH_REMATCH[1]}"

			declare -i j
			for ((j = 0; j < ${#opt_chars}; ++j)); do
				declare opt_char="${opt_chars:j:1}"

				declare opt_handle
				opt_handle="$(cli_options_find_by_short_char "$opt_char")"

				if [ -n "$opt_handle" ]; then
					declare opt_arg='none:'
					if cli_options_option_requires_arg "$opt_handle"; then
						if (((j + 1) < ${#opt_chars})); then
							opt_arg="present:${opt_chars:j + 1}"
							j=${#opt_chars}
						elif (((cli_arg_i + 1) < $#)); then
							((++cli_arg_i))
							opt_arg="present:${cli_args[cli_arg_i]}"
						fi
					fi

					if cli_options_option_is_high_prio "$opt_handle"; then
						if [ -z "$cli_option_high_prio_handle" ]; then
							cli_option_high_prio_handle="$opt_handle"
							cli_option_high_prio_origin="-$opt_char"
							cli_option_high_prio_arg="$opt_arg"
						fi
					else
						cli_option_low_prio_handles+=("$opt_handle")
						cli_option_low_prio_origins+=("-$opt_char")
						cli_option_low_prio_args+=("$opt_arg")
					fi

					unset -v opt_arg
				elif [ -z "$cli_first_invalid_opt" ]; then
					cli_first_invalid_opt="-$opt_char"
				fi

				unset -v opt_handle opt_char
			done

			unset -v j opt_chars

			continue
		fi
	fi

	declare pathname
	pathname="$(normalize_pathname "$arg" && printf x)"
	pathname="${pathname%x}"

	bak_pathnames+=("$pathname")

	unset -v pathname
	unset -v arg
done

unset -v cli_process_opts \
         cli_arg_i cli_args


if [ -n "$cli_option_high_prio_handle" ]; then
	declare -a args_to_pass=()

	if [[ "$cli_option_high_prio_arg" =~ ^'present:'(.*)$ ]]; then
		args_to_pass+=("${BASH_REMATCH[1]}")
	fi

	cli_options_execute "$cli_option_high_prio_handle" "$cli_option_high_prio_origin" "${args_to_pass[@]}"
	exit
fi
unset -v cli_option_high_prio_arg \
         cli_option_high_prio_origin \
         cli_option_high_prio_handle


if [ -n "$cli_first_invalid_opt" ]; then
	usage_errlog "$cli_first_invalid_opt: invalid option"
	exit 5
fi
unset -v cli_first_invalid_opt


declare -i i
for ((i = 0; i < ${#cli_option_low_prio_handles[@]}; ++i)); do
	declare -a args_to_pass=()

	if [[ "${cli_option_low_prio_args[i]}" =~ ^'present:'(.*)$ ]]; then
		args_to_pass+=("${BASH_REMATCH[1]}")
	fi

	cli_options_execute "${cli_option_low_prio_handles[i]}" "${cli_option_low_prio_origins[i]}" "${args_to_pass[@]}"

	unset -v args_to_pass
done
unset -v i \
         cli_option_low_prio_args \
         cli_option_low_prio_origins \
         cli_option_low_prio_handles


declare -i i
for ((i = 0; i < ${#bak_pathnames[@]}; ++i)); do
	declare bak_pathname
	bak_pathname="${bak_pathnames[i]}"

	if [ -z "$bak_pathname" ]; then
		if ((${#bak_pathnames[@]} == 1)); then
			errlog 'argument must not be empty'
		else
			errlog "argument $((i + 1)): must not empty"
		fi
		exit 9
	fi

	if ! starts_with "$bak_pathname" '/'; then
		errlog "$bak_pathname: must be an absolute path"
		exit $exc_usage_argument_must_be_absolute_pathname
	fi

	unset -v bak_pathname
done
unset -v i


if [ -z "${HOME-}" ]; then
	errlog 'HOME environment variable must not be unset or empty'
	exit $exc_error_env_var_must_not_be_unset_or_empty
fi

if ! starts_with "$HOME" '/'; then
	errlog "$HOME: HOME environment variable must be an absolute path"
	exit $exc_error_env_var_must_be_absolute_pathname
fi

HOME="$(normalize_pathname "$HOME" && printf x)"
HOME="${HOME%x}"
readonly HOME
export HOME


declare -A var_names_with_default_values
var_names_with_default_values=(
	[XDG_DATA_HOME]="$HOME/.local/share"
	[XDG_CONFIG_HOME]="$HOME/.config"
	[XDG_STATE_HOME]="$HOME/.local/state"
	[XDG_CACHE_HOME]="$HOME/.cache"
)

declare var_name
for var_name in "${!var_names_with_default_values[@]}"; do
	declare pathname
	eval "pathname=\"\${$var_name-}\""

	if [ -n "$pathname" ] && ! starts_with "$pathname" '/'; then
		errlog "$pathname: $var_name environment variable must be an absolute path"
		exit $exc_error_env_var_must_be_absolute_pathname
	fi

	if [ -z "$pathname" ]; then
		pathname="${var_names_with_default_values["$var_name"]}"
	fi

	pathname="$(normalize_pathname "$pathname" && printf x)"
	pathname="${pathname%x}"

	eval "$var_name=\"\$pathname\""

	eval "readonly $var_name"
	eval "export $var_name"

	unset -v pathname
done
unset -v var_name

unset -v var_names_with_default_values


declare config_dir_pathname
config_dir_pathname="$(normalize_pathname "$XDG_CONFIG_HOME/mkbak")"
readonly config_dir_pathname

declare config_file_pathname
config_file_pathname="$(normalize_pathname "$config_dir_pathname/mkbak.conf")"
readonly config_file_pathname


readonly config_key_pattern='[a-z_]+'

# $1: config key
# $2: (optional) fallback value
# stdout: the value of the config key, or the given fallback value if the config key doesn't exist / couldn't be read
function config_read_value() {
	local requested_key fallback_value

	case $# in
		(0)
			internal_errlog 'missing argument: <key> [<fallback_value>]'
			return 3
			;;
		(1)
			if [ -z "$1" ]; then
				internal_errlog 'argument: must not be empty'
				return 9
			fi

			requested_key="$1"
			fallback_value=''
			;;
		(2)
			if [ -z "$1" ]; then
				internal_errlog 'argument 1: must not be empty'
				return 9
			fi

			if [ -z "$2" ]; then
				internal_errlog 'argument 2: must not be empty'
				return 9
			fi

			requested_key="$1"
			fallback_value="$2"
			;;
		(*)
			internal_errlog "too many arguments: $(($# - 2))"
			return 4
			;;
	esac

	readonly fallback_value requested_key

	if [[ ! "$requested_key" =~ ^$config_key_pattern$ ]]; then
		internal_errlog "$requested_key: does not match: /^$config_key_pattern\$/"
		return 12
	fi


	if [ ! -f "$config_file_pathname" ] || [ ! -r "$config_file_pathname" ]; then
		printf '%s' "$fallback_value"
		return
	fi


	local line
	while read -r line; do
		if [[ "$line" =~ ^([^'#']*)'#' ]]; then
			line="$(trim_ws "${BASH_REMATCH[1]}")"
		fi

		local key value
		if [[ ! "$line" =~ ^(${config_key_pattern})[[:space:]]*'='[[:space:]]*(.*)$ ]]; then
			continue
		fi
		key="${BASH_REMATCH[1]}"
		value="${BASH_REMATCH[2]}"

		if [ "$key" = "$requested_key" ]; then
			printf '%s' "$value"
			return
		fi

		unset -v value key
	done < "$config_file_pathname"
	unset -v line

	printf '%s' "$fallback_value"
}
readonly -f config_read_value

readonly integer_pattern='[+-]?[0-9]+'

# $1: config key
# $2: fallback value
# stdout: the value of the config key, or the given fallback value if the config key is not an integer or
#         doesn't exist / couldn't be read
function config_read_integer() {
	local requested_key fallback_value

	case $# in
		(0)
			internal_errlog 'missing arguments: <key> <fallback_value>'
			return 3
			;;
		(1)
			internal_errlog 'missing argument: <fallback_value>'
			return 3
			;;
		(2)
			if [ -z "$1" ]; then
				internal_errlog 'argument 1: must not be empty'
				return 9
			fi
			if [[ ! "$1" =~ ^$config_key_pattern$ ]]; then
				internal_errlog "$1: does not match: /^$config_key_pattern\$/"
				return 12
			fi

			if [ -z "$2" ]; then
				internal_errlog 'argument 2: must not be empty'
				return 9
			fi
			if [[ ! "$2" =~ ^$integer_pattern$ ]]; then
				internal_errlog "$2: not an integer"
				return 10
			fi

			requested_key="$1"
			fallback_value="$2"
			;;
		(*)
			internal_errlog "too many arguments: $(($# - 2))"
			return 4
			;;
	esac

	readonly fallback_value requested_key


	local value
	value="$(config_read_value "$requested_key" "$fallback_value")"

	if [[ ! "$value" =~ ^$integer_pattern$ ]]; then
		value="$fallback_value"
	fi

	value="${value#+}"

	if [[ "$value" =~ ^('-'?)'0'+('0'|[1-9][0-9]*)$ ]]; then
		value="${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
	fi

	value=$((value))

	readonly value

	printf '%s' "$value"
}
readonly -f config_read_integer


readonly config_key_default_input_file_pathname='default_input_file_path'

declare default_input_file_pathname
default_input_file_pathname=$(config_read_value "$config_key_default_input_file_pathname")

if [ -n "$default_input_file_pathname" ]; then
	if [[ "$default_input_file_pathname" =~ ^'~'('/'.*)?$ ]]; then
		default_input_file_pathname="${HOME}${BASH_REMATCH[1]}"
	elif [[ ! "$default_input_file_pathname" =~ ^'/' ]]; then
		errlog "$default_input_file_pathname: $config_key_default_input_file_pathname config key must either start with a tilde (~) or be an absolute path"
		exit 79
	fi
fi

readonly default_input_file_pathname


#region checking commands

if ! command_exists tar; then
	errlog 'tar: program missing'
	exit 27
fi

declare tar_version_info
if tar_version_info="$(tar --version)"; then
	tar_version_info="$(head -n1 <<< "$tar_version_info")"
else
	tar_version_info=''
fi
if [[ ! "$tar_version_info" =~ ^'tar (GNU tar)' ]]; then
	errlog "GNU tar is required"
	exit $exc_error_gnu_tar_required
fi
unset -v tar_version_info


if $include_user_crontab; then
	if ! command_exists crontab; then
		errlog 'crontab: program missing'
		exit 27
	fi
fi

#endregion

#region checking & reading input file

# only take the configured default input file pathname when no pathnames have been given on the command line and
# no input file has been specified
if ((${#bak_pathnames[@]} == 0)) && [ "$bak_pathnames_input_source" = 'default:' ]; then
	if [ -z "$default_input_file_pathname" ]; then
		errlog "$config_key_default_input_file_pathname config key must not be missing or empty"
		exit 80
	fi

	bak_pathnames_input_source="file:$default_input_file_pathname"
fi

function read_pathnames_from_input() {
	local input_source

	case $# in
		(0)
			input_source='stdin:'
			;;
		(1)
			if [ -z "$1" ]; then
				internal_errlog "argument must not be empty"
				return 9
			fi

			input_source="file:$1"
			;;
		(*)
			internal_errlog "too many arguments: $(($# - 1))"
			return 4
			;;
	esac

	readonly input_source


	local input_source_name

	case "$input_source" in
		('file:'?*) input_source_name="${input_source#file:}" ;;
		('stdin:')  input_source_name='<stdin>'               ;;
	esac

	readonly input_source_name


	local -i row
	row=0

	local line
	while read -r line; do
		((++row))

		if [[ "$line" =~ ^([^'#']*)'#' ]]; then
			line="$(trim_ws "${BASH_REMATCH[1]}")"
		fi

		if [ -z "$line" ]; then
			continue
		fi

		case "$line" in
			('~'*)
				local substring_after_tilde
				substring_after_tilde="${line#\~}"

				if [ -n "$substring_after_tilde" ] && ! starts_with "$substring_after_tilde" '/'; then
					errlog "$input_source_name:$row: $line: a leading tilde ('~') must be followed by either nothing or a slash"
					exit $exc_error_input_file_malformed
				fi

				line="${HOME}${substring_after_tilde}"

				unset -v substring_after_tilde
				;;
			('$'*)
				if [[ ! "$line" =~ ^'$'([A-Za-z_][A-Za-z0-9_]*)([^A-Za-z0-9_].*)?$ ]]; then
					errlog "$input_source_name:$row: $line: a leading dollar ('$') must be followed by a valid variable name"
					exit $exc_error_input_file_malformed
				fi


				local var_name substring_after_var_name
				var_name="${BASH_REMATCH[1]}"
				substring_after_var_name="${BASH_REMATCH[2]}"

				if [[ ! "$var_name" =~ ^[A-Z_][A-Z0-9_]*$ ]]; then
					errlog "$input_source_name:$row: $var_name: variable names must not contain lowercase letters"
					exit $exc_error_input_file_malformed
				fi

				if [ -n "$substring_after_var_name" ] && ! starts_with "$substring_after_var_name" '/'; then
					errlog "$input_source_name:$row: $line: a leading variable must be followed by either nothing or a slash"
					exit $exc_error_input_file_malformed
				fi


				local var_value
				eval "var_value=\"\${$var_name-}\""

				if [ -z "$var_value" ]; then
					errlog "$input_source_name:$row: $var_name: environment variable must not be unset or empty"
					exit $exc_error_input_file_malformed
				fi

				if ! starts_with "$var_value" '/'; then
					errlog "$input_source_name:$row: $var_value: value of environment variable $var_name must be an absolute path"
					exit $exc_error_input_file_malformed
				fi


				line="${var_value}${substring_after_var_name}"


				unset -v var_value \
				         substring_after_var_name var_name
				;;
		esac

		line="$(normalize_pathname "$line" && printf x)"
		line="${line%x}"

		if ! starts_with "$line" '/'; then
			errlog "$input_source_name:$row: $line: path must be absolute"
			exit $exc_error_input_file_malformed
		fi

		bak_pathnames+=("$line")
	done < <(case "$input_source" in
		         ('file:'?*) cat -- "${input_source#file:}" ;;
		         ('stdin:')  cat                            ;;
	         esac)
}
readonly -f read_pathnames_from_input

case "$bak_pathnames_input_source" in
	('file:'?*)
		declare bak_pathnames_input_file_pathname
		bak_pathnames_input_file_pathname="${bak_pathnames_input_source#file:}"

		declare result
		result="$(resolve_pathname "$bak_pathnames_input_file_pathname" && printf x)"
		result="${result%x}"

		case "$result" in
			('directory:'?*)
				errlog "${result#directory:}: not a file"
				exit 26
				;;
			('EACCESS:'?*)
				errlog "${result#EACCESS:}: permission denied: search permissions missing"
				exit 77
				;;
			('ENOENT:'*)
				errlog "${result#ENOENT:}: no such file or directory"
				exit 24
				;;
			('ENOTDIR:'?*)
				errlog "${result#ENOTDIR:}: not a directory"
				exit 26
				;;
		esac

		unset -v result

		if [ ! -e "$bak_pathnames_input_file_pathname" ]; then
			errlog "$bak_pathnames_input_file_pathname: no such file"
			exit 24
		fi

		if [ -d "$bak_pathnames_input_file_pathname" ]; then
			errlog "$bak_pathnames_input_file_pathname: not a file"
			exit 26
		fi

		if [ ! -r "$bak_pathnames_input_file_pathname" ]; then
			errlog "$bak_pathnames_input_file_pathname: permission denied: read permissions missing"
			exit 77
		fi

		read_pathnames_from_input "$bak_pathnames_input_file_pathname"

		unset -v bak_pathnames_input_file_pathname
		;;
	('stdin:')
		read_pathnames_from_input
		;;
	('default:')
		# nothing
		;;
	(*)
		errlog "emergency stop: wrong format for 'bak_pathnames_input_source' variable: $bak_pathnames_input_source"
		exit 123
		;;
esac

unset -v bak_pathnames_input_source

#endregion

declare user_was_prompted
user_was_prompted=false


declare -a missing_pathnames
missing_pathnames=()

declare bak_pathname
for bak_pathname in "${bak_pathnames[@]}"; do
	if [ -e "$bak_pathname" ]; then
		continue
	fi

	missing_pathnames+=("$bak_pathname")

	if [ -t 0 ]; then
		declare -i exc
		exc=0
		prompt_yes_no "The path '$bak_pathname' does not exist. Continue anyway?" default=no ||
			exc=$?

		user_was_prompted=true

		case $exc in
			(0)
				# continue
				;;
			(32)
				log 'Aborting.'
				exit $exc_feedback_prompt_abort
				;;
			(*)
				exit $exc
				;;
		esac

		unset -v exc
	fi
done
unset -v bak_pathname

readonly missing_pathnames

#region checking user crontab

if $include_user_crontab; then
	declare crontab_backup_file_pathname
	crontab_backup_file_pathname="$(normalize_pathname "$HOME/crontab_backup")"
	readonly crontab_backup_file_pathname

	declare result
	result="$(resolve_pathname "$crontab_backup_file_pathname")"

	case "$result" in
		('directory:'?*)
			errlog "${result#directory:}: not a file"
			exit 26
			;;
		('EACCESS:'?*)
			errlog "${result#EACCESS:}: permission denied: search permissions missing"
			exit 77
			;;
		('ENOENT:'*)
			errlog "${result#ENOENT:}: no such file or directory"
			exit 24
			;;
		('ENOTDIR:'?*)
			errlog "${result#ENOTDIR:}: not a directory"
			exit 26
			;;
	esac

	unset -v result

	if [ -e "$crontab_backup_file_pathname" ]; then
		if [ -d "$crontab_backup_file_pathname" ]; then
			errlog "$crontab_backup_file_pathname: not a file"
			exit 26
		fi

		if [ -t 0 ]; then
			declare -i exc
			exc=0
			prompt_yes_no "The file '$crontab_backup_file_pathname' already exists. Overwrite?" default=yes ||
				exc=$?

			user_was_prompted=true

			case $exc in
				(0)
					# continue
					;;
				(32)
					log 'Aborting.'
					exit $exc_feedback_prompt_abort
					;;
				(*)
					exit $exc
					;;
			esac

			unset -v exc
		fi
	fi

	declare crontab_backup_file_parent_dir_pathname
	crontab_backup_file_parent_dir_pathname="$(dirname -- "$crontab_backup_file_pathname" && printf x)"
	crontab_backup_file_parent_dir_pathname="${crontab_backup_file_parent_dir_pathname%$'\nx'}"

	if [ ! -w "$crontab_backup_file_parent_dir_pathname" ]; then
		errlog "$crontab_backup_file_parent_dir_pathname: permission denied: write permission missing"
		exit 77
	fi

	unset -v crontab_backup_file_parent_dir_pathname


	bak_pathnames+=("$crontab_backup_file_pathname")
fi

#endregion

if ((${#bak_pathnames[@]} == 0)); then
	errlog 'no paths to backup given'
	exit $exc_error_no_bak_pathnames
fi

#region checking output file

declare output_archive_file_pathname

case "$output_archive_target" in
	('file:'?*)
		output_archive_file_pathname="${output_archive_target#file:}"

		declare result
		result="$(resolve_pathname "$output_archive_file_pathname" && printf x)"
		result="${result%x}"

		case "$result" in
			('directory:'?*)
				errlog "${result#directory:}: not a file"
				exit 26
				;;
			('EACCESS:'?*)
				errlog "${result#EACCESS:}: permission denied: search permissions missing"
				exit 77
				;;
			('ENOENT:'*)
				errlog "${result#ENOENT:}: no such file or directory"
				exit 24
				;;
			('ENOTDIR:'?*)
				errlog "${result#ENOTDIR:}: not a directory"
				exit 26
				;;
		esac

		unset -v result

		if [ -e "$output_archive_file_pathname" ]; then
			if [ -d "$output_archive_file_pathname" ]; then
				errlog "$output_archive_file_pathname: not a file"
				exit 26
			fi

			if [ -t 0 ]; then
				declare -i exc
				exc=0
				prompt_yes_no "The file '$output_archive_file_pathname' already exists. Overwrite?" default=no ||
					exc=$?

				user_was_prompted=true

				case $exc in
					(0)
						# continue
						;;
					(32)
						log 'Aborting.'
						exit $exc_feedback_prompt_abort
						;;
					(*)
						exit $exc
						;;
				esac

				unset -v exc
			fi

			if [ ! -w "$output_archive_file_pathname" ]; then
				errlog "$output_archive_file_pathname: permission denied: write permission missing"
				exit 77
			fi
		else
			declare output_archive_parent_dir_pathname
			output_archive_parent_dir_pathname="$(dirname -- "$output_archive_file_pathname" && printf x)"
			output_archive_parent_dir_pathname="${output_archive_parent_dir_pathname%$'\nx'}"

			if [ ! -w "$output_archive_parent_dir_pathname" ]; then
				errlog "$output_archive_parent_dir_pathname: permission denied: write permission missing"
				exit 77
			fi

			unset -v output_archive_parent_dir_pathname
		fi
		;;
	('stdout:')
		output_archive_file_pathname=''
		;;
	(*)
		errlog "emergency stop: wrong format for 'output_archive_target' variable: $output_archive_target"
		exit 123
		;;
esac

readonly output_archive_file_pathname

unset -v output_archive_target

#endregion

readonly user_was_prompted

#region checking copy destinations

declare copy_destination_pathname
for copy_destination_pathname in "${copy_destination_pathnames[@]}"; do
	declare result
	result="$(resolve_pathname "$copy_destination_pathname" && printf x)"
	result="${result%x}"

	case "$result" in
		('EACCESS:'?*)
			errlog "${result#EACCESS:}: permission denied: search permissions missing"
			exit 77
			;;
		('ENOENT:'*)
			errlog "${result#ENOENT:}: no such file or directory"
			exit 24
			;;
		('ENOTDIR:'?*)
			errlog "${result#ENOTDIR:}: not a directory"
			exit 26
			;;
	esac

	unset -v result
done
unset -v copy_destination_pathname

#endregion

#region executing final commands

function write_bak_pathnames_null_separated() {
	local -i i
	i=1

	printf '%s' "${bak_pathnames[0]}"

	for ((; i < ${#bak_pathnames[@]}; ++i)); do
		printf '\0%s' "${bak_pathnames[i]}"
	done
}
readonly -f write_bak_pathnames_null_separated


declare -a tar_args
tar_args=(
	--create --gzip
	--verbose
)


if [ -n "$output_archive_file_pathname" ]; then
	tar_args+=(--force-local --file="$output_archive_file_pathname")
else
	tar_args+=(--to-stdout)
fi


declare output_archive_file_absolute_pathname

output_archive_file_absolute_pathname="$(ensure_absolute_pathname "$output_archive_file_pathname" && printf x)"
output_archive_file_absolute_pathname="${output_archive_file_absolute_pathname%x}"

output_archive_file_absolute_pathname="$(escape_glob_pattern "$output_archive_file_absolute_pathname" && printf x)"
output_archive_file_absolute_pathname="${output_archive_file_absolute_pathname%x}"

tar_args+=(
	--exclude='node_modules'
	--exclude-tag='.nobak'
	--exclude-ignore='.nobakpattern'

	--exclude="$output_archive_file_absolute_pathname"
)

unset -v output_archive_file_absolute_pathname


declare missing_pathname
for missing_pathname in "${missing_pathnames[@]}"; do
	missing_pathname="${missing_pathname%/}"

	missing_pathname="$(escape_glob_pattern "$missing_pathname" && printf x)"
	missing_pathname="${missing_pathname%x}"

	tar_args+=(--exclude="$missing_pathname")
done
unset -v missing_pathname


tar_args+=(
	--absolute-names
	--verbatim-files-from --null --files-from='-'
)


if $include_user_crontab; then
	function remove_crontab_file() {
		rm -f -- "$crontab_backup_file_pathname"
	}
	readonly -f remove_crontab_file

	crontab -l > "$crontab_backup_file_pathname"
	trap remove_crontab_file EXIT TERM INT QUIT
fi

if $user_was_prompted; then
	log
fi
tar "${tar_args[@]}" < <(write_bak_pathnames_null_separated)

if $include_user_crontab; then
	remove_crontab_file
	trap - EXIT TERM INT QUIT
fi


declare copy_destination_pathname
for copy_destination_pathname in "${copy_destination_pathnames[@]}"; do
	cp -- "$output_archive_file_pathname" "$copy_destination_pathname"
done
unset -v copy_destination_pathname

#endregion
