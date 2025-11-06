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

#region Processing arguments

print_usage() {
	printf 'usage: %s copy [<text>]\n' "$argv0"
	printf '   or: %s clear\n' "$argv0"
	printf '   or: %s paste\n' "$argv0"
}

if [ $# -lt 1 ]; then
	{
		printf '%s: missing argument: copy | clear | paste\n' "$argv0"
		print_usage
	} >&2
	exit 3
fi

if [ -z "$1" ]; then
	if [ $# -eq 1 ]; then
		tmp=''
	else
		tmp=' 1:'
	fi
	readonly tmp

	{
		printf '%s: argument%s must not be empty\n' "$argv0" "$tmp"
		print_usage
	} >&2
	exit 9
fi

case "$1" in
	('copy')
		if [ $# -gt 2 ]; then
			{
				printf '%s %s: too many arguments: %d\n' "$argv0" "$1" $(($# - 2))
				print_usage
			} >&2
			exit 4
		fi

		if [ $# -ge 2 ]; then
			operation="copy_string:$2"
		else
			operation='copy_from_stdin'
		fi
		;;
	('clear')
		if [ $# -gt 1 ]; then
			{
				printf '%s %s: too many arguments: %d\n' "$argv0" "$1" $(($# - 1))
				print_usage
			} >&2
			exit 4
		fi

		operation='clear'
		;;
	('paste')
		if [ $# -gt 1 ]; then
			{
				printf '%s %s: too many arguments: %d\n' "$argv0" "$1" $(($# - 1))
				print_usage
			} >&2
			exit 4
		fi

		operation='paste_to_stdout'
		;;
	(*)
		{
			printf '%s: %s: not an operation\n' "$argv0" "$1"
			print_usage
		} >&2
		exit 13
		;;
esac

readonly operation
unset -f print_usage

#endregion

command_exists() {
	command -v "$1" > '/dev/null'
}

#region Clipboard implementations

# TODO: X11 `xsel`

#region Determining implementations priority order

case "$(uname | tr '[:upper:]' '[:lower:]')" in
	(*'linux'*)
		implementations="wayland_wl_clipboard x11_xclip termux macos windows"
		;;
	(*'darwin'*)
		implementations="macos wayland_wl_clipboard x11_xclip termux windows"
		;;
	(*'mingw'*)
		implementations="windows wayland_wl_clipboard x11_xclip termux macos"
		;;
	(*)
		implementations="wayland_wl_clipboard x11_xclip macos windows termux"
		;;
esac
# shellcheck disable=SC2086
implementations="$(printf '%s\n' $implementations && printf x)"
implementations="${implementations%x}"

prioritize_implementation() {
	implementations="$(printf '%s' "$implementations" | sed /"$1"/d)" || return
	implementations="$(printf '%s\n%s\nx' "$1" "$implementations")" || return
	implementations="${implementations%x}"
}
prioritize_wayland_only() {
	prioritize_implementation wayland_wl_clipboard
}
prioritize_x11_only() {
	#prioritize_implementation x11_sel || return
	prioritize_implementation x11_xclip
}
prioritize_wayland() {
	# Ghostty has some weirdness with `wl-copy`/`wl-paste`, but seemingly only sometimes?
	if [ "${TERM-}" != 'xterm-ghostty' ]; then
		prioritize_x11_only || return
		prioritize_wayland_only
	else
		prioritize_wayland_only || return
		prioritize_x11_only
	fi
}

if [ -n "${TERMUX_VERSION-}" ]; then
	prioritize_implementation termux
fi

case "$(printf '%s' "${XDG_SESSION_TYPE-}" | tr '[:upper:]' '[:lower:]')" in
	(*'wayland'*)
		prioritize_wayland
		;;
	(*'x11'*)
		prioritize_wayland_only
		prioritize_x11_only
		;;
esac

if [ -n "${WAYLAND_DISPLAY-}" ]; then
	prioritize_wayland
fi

unset -f prioritize_wayland prioritize_x11_only prioritize_wayland_only prioritize_implementation
readonly implementations

#endregion

#region Wayland

if command_exists wl-copy; then
	wayland_wl_clipboard__copy_from_stdin() { wl-copy; }

	wayland_wl_clipboard__copy_string() {
		wl-copy -- "$1"
	}

	wayland_wl_clipboard__clear() {
		wl-copy --clear
	}
fi

if command_exists wl-paste; then
	wayland_wl_clipboard__paste_to_stdout() {
		wl-paste --no-newline
	}
fi

#endregion

#region X11

if command_exists xclip; then
	x11_xclip__copy_from_stdin() {
		xclip -in -selection clipboard
	}

	x11_xclip__copy_string() {
		printf '%s' "$1" | x11_xclip__copy_from_stdin
	}

	x11_xclip__clear() {
		xclip -in -selection clipboard '/dev/null'
	}

	x11_xclip__paste_to_stdout() {
		# Without explicitly passing the option -target, `xclip` will only output plaintext targets and will fail
		# otherwise.

		set -- "$(xclip -out -target TARGETS -selection clipboard | grep -Ev '^(TARGETS|TIMESTAMP)$')" || return
		set -- "$1" "$(printf '%s' "$1" | wc -l)" || return

		if [ -n "$1" ] && [ $# -eq 0 ]; then
			# Single target, specify it explicitly so that `xclip` will output it if its non-plaintext.
			xclip -out -target "$1" -selection clipboard
		else
			# Let `xclip` decide which target to use.
			# This can certainly still fail.
			xclip -out -selection clipboard
		fi
	}
fi

#endregion

#region macOS

# TODO: This is untested (I don't own a Mac).

if command_exists pbcopy; then
	macos__copy_from_stdin() { pbcopy; }

	macos__copy_string() {
		printf '%s' "$1" | macos__copy_from_stdin
	}

	macos__clear() {
		termux__copy_from_stdin < '/dev/null'
	}
fi

if command_exists pbpaste; then
	macos__paste_to_stdout() { pbpaste; }
fi

#endregion

#region Windows

if command_exists clip; then
	windows__copy_from_stdin() { clip; }

	windows__copy_string() {
		printf '%s' "$1" | windows__copy_from_stdin
	}

	windows__clear() {
		# Using `clip < /dev/null` doesn't work. (The program seems to detect what stdin is?)
		printf '' | windows__copy_from_stdin
	}
fi

if command_exists powershell; then
	windows__paste_to_stdout() {
		powershell -command Get-Clipboard
	}
fi

#endregion

#region Termux

if command_exists termux-clipboard-set; then
	termux__copy_from_stdin() { termux-clipboard-set; }

	termux__copy_string() {
		termux-clipboard-set -- "$1"
	}

	termux__clear() {
		termux__copy_string ''
	}
fi

if command_exists termux-clipboard-get; then
	termux__paste_to_stdout() { termux-clipboard-get; }
fi

#endregion

#endregion

is_function() {
	# `command -v` will output an absolute path if its operand is found on the PATH, which means if its *not*
	# an absolute path, then must be either a shell built-in, function or alias.
	# Aliases are not preserved for executed scripts.
	command -v "$1" | grep -Eqv '[/\\]'
}

run_operation_with_arguments() {
	for implementation in $implementations; do
		func="${implementation}__$1" || return

		if is_function "$func"; then
			shift || return
			"$func" "$@"
			return
		fi

		unset -v func
	done
	unset -v implementation

	printf '%s: system has no clipboard implementation installed\n' "$argv0" >&2
	return 48
}

case "$operation" in
	('copy_from_stdin'|'clear'|'paste_to_stdout')
		run_operation_with_arguments "$operation"
		;;

	('copy_string:'*)
		string="${operation#copy_string:}"
		readonly string

		run_operation_with_arguments 'copy_string' "$string"
		;;

	(*)
		# shellcheck disable=SC2016
		printf '%s: variable `operation` is invalid\n' "$argv0" >&2

		exit 104
		;;
esac
