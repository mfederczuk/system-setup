#!/bin/sh
# -*- sh -*-
# vim: syntax=sh
# code: language=shellscript

# Copyright (c) 2023 Michael Federczuk
# SPDX-License-Identifier: MPL-2.0 AND Apache-2.0

# POSIX shellscript to execute the `notify-send` command from a non-graphical environment
# this script is mainly intended to be used by cron jobs to show notifications
# since cron jobs don't run in a graphical environment, the `notify-send` command doesn't work
# this script will extract the environment variables `DBUS_SESSION_BUS_ADDRESS` and `DISPLAY` from the running
# `gnome-shell` process and another user process, respectfully, and then export these variables to the current shell
# so that `notify-send` will have access to them

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

#region environment preconditions

command_exists() {
	command -v "$1" > '/dev/null'
}

if ! command_exists notify-send; then
	printf '%s: notify-send: program missing\n' "$argv0" >&2
	exit 27
fi

if { [ -z "${DBUS_SESSION_BUS_ADDRESS-}" ] || [ -z "${DISPLAY-}" ]; } && ! command_exists pgrep; then
	printf '%s: pgrep: program missing\n' "$argv0" >&2
	exit 27
fi

unset -f command_exists

#endregion

#region args

print_usage() {
	printf 'usage: %s <app_name> [<summary>]\n' "$argv0" >&2
}

case $# in
	(0)
		printf '%s: missing arguments: <app_name> [<summary>]\n' "$argv0" >&2
		print_usage
		exit 3
		;;
	(1)
		if [ -z "$1" ]; then
			printf '%s: argument must not be empty\n' "$argv0" >&2
			print_usage
			exit 9
		fi

		notification_app_name="$1"
		notification_summary="$notification_app_name"
		;;
	(2)
		if [ -z "$1" ]; then
			printf '%s: argument 1: must not be empty\n' "$argv0" >&2
			print_usage
			exit 9
		fi

		if [ -z "$2" ]; then
			printf '%s: argument 2: must not be empty\n' "$argv0" >&2
			print_usage
			exit 9
		fi

		notification_app_name="$1"
		notification_summary="$2"
		;;
	(*)
		printf '%s: too many arguments: %i\n' "$argv0" $(($# - 2)) >&2
		print_usage
		exit 4
		;;
esac

readonly notification_summary notification_app_name

unset -f print_usage

#endregion

#region extracting environment

# extracts an environment variable from a target process and exports that variable in the current shell
#
# args:
#  $1: PID
#  $2: environment variable name
export_env_var_from_process() {
	# first octaldump the environment of the process
	# this should output the environment in the form of:
	#         " OOO OOO OOO OOO OOO OOO OOO OOO OOO OOO OOO OOO OOO OOO OOO OOO"
	#         " OOO OOO OOO OOO OOO OOO OOO OOO OOO OOO OOO OOO OOO OOO OOO OOO"
	#         " OOO OOO OOO OOO OOO"
	# ... where each substring of "OOO" is a 3-digit octal number, left-padded with zeros
	environ="$(od -An -to1 -v "/proc/$1/environ")"

	# replace every octal-encoded NUL character (substring of "000") with an underscore (it doesn't matter which
	# character is used as a replacement, as long as it's neither an octal digit nor a whitespace character)
	environ="$(printf '%s' "$environ" | sed -e s/'000'/'_'/g)"

	# append the prefix "\0" to every octal number
	# this prepares the substrings so that they can be interpreted correctly by POSIX printf's %b conversion specifier
	environ="$(printf '%s' "$environ" | sed -e s/'\([0-7][0-7][0-7]\)'/'\\0\1'/g)"

	# strip all whitespace characters from the octaldump
	environ="$(printf '%s' "$environ" | tr -d '[:space:]')"

	# replace the underscores with newlines
	environ="$(printf '%s' "$environ" | tr '_' '\n')"

	# now the variable `environ` holds the environment of the target process in the form of "<var_name>=<var_value>",
	# encoded as printf's %b escape sequences, separated by newlines

	while read -r line; do
		# convert all escaped octal numbers into their respectful byte using POSIX printf's %b conversion specifier
		# the extra trailing 'x' character is required so that any trailing newlines aren't stripped away
		line="$(printf '%bx' "$line")"
		line="${line%x}"

		var_name="${line%%=*}"
		var_value="${line#"$var_name="}"

		if [ "$var_name" != "$2" ]; then
			continue
		fi

		export "$var_name"="$var_value"
		break
	done <<-EOF
		$environ
	EOF

	unset -v var_value var_name line environ
}

if [ -z "${DBUS_SESSION_BUS_ADDRESS-}" ] || [ -z "${DISPLAY-}" ]; then
	user_id="$(id -u)"
	readonly user_id
fi

if [ -z "${DBUS_SESSION_BUS_ADDRESS-}" ]; then
	gnome_shell_pid="$(pgrep --newest --euid "$user_id" --exact gnome-shell)"

	if [ -z "$gnome_shell_pid" ]; then
		printf '%s: cannot find active GNOME shell to extract D-Bus address from\n' "$argv0" >&2
		exit 48
	fi

	export_env_var_from_process "$gnome_shell_pid" DBUS_SESSION_BUS_ADDRESS

	unset -v gnome_shell_pid

	if [ -z "${DBUS_SESSION_BUS_ADDRESS-}" ]; then
		printf "%s: GNOME shell doesn't have D-Bus address environment variable\n" "$argv0" >&2
		exit 49
	fi
fi

if [ -z "${DISPLAY-}" ]; then
	# not using the GNOME shell here because it doesn't have the `DISPLAY` env var set
	pid="$(pgrep --newest --older 10 --euid "$user_id")"

	if [ -n "$pid" ]; then
		export_env_var_from_process "$pid" DISPLAY
	fi

	unset -v pid

	if [ -z "${DISPLAY-}" ]; then
		# this should work as fallback
		DISPLAY=':0'
		export DISPLAY
	fi
fi

#endregion

notify-send --app-name="$notification_app_name" --transient "$notification_summary"
