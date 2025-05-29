#!/bin/bash
# -*- sh -*-
# vim: syntax=sh
# code: language=shellscript

# Copyright (c) 2025 Michael Federczuk
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

# Using an associative array as a set.
declare -A effect_names
effect_names=(
	['reset']='x'

	['color.black']='x'
	['color.dark_gray']='x'
	['color.light_gray']='x'
	['color.white']='x'

	['color.red']='x'
	['color.green']='x'
	['color.blue']='x'
	['color.yellow']='x'
	['color.magenta']='x'
	['color.cyan']='x'

	['color.bright_red']='x'
	['color.bright_green']='x'
	['color.bright_blue']='x'
	['color.bright_yellow']='x'
	['color.bright_magenta']='x'
	['color.bright_cyan']='x'

	['font.weight.bold']='x'

	['font.style.regular']='x'
	['font.style.italic']='x'
)
readonly effect_names

#region argument

declare effect_name

case $# in
	(0)
		{
			printf '%s: missing argument: <effect_name>\n' "$argv0"
			printf 'usage: %s <effect_name>\n' "$argv0"
		} >&2
		exit 3
		;;
	(1)
		if [ -z "$1" ]; then
			printf '%s: argument must not be empty\n' "$argv0" >&2
			return 9
		fi

		effect_name="$1"

		if [[ "${effect_names["$effect_name"]-}" != 'x' ]]; then
			printf '%s: %s: unknown effect\n' "$argv0" "$effect_name" >&2
			exit 13
		fi
		;;
	(*)
		{
			printf '%s: too many arguments: %i\n' "$argv0" $(($# - 1))
			printf 'usage: %s <effect_name>\n' "$argv0"
		} >&2
		exit 4
		;;
esac

readonly effect_name

#endregion

#region types

function type__none() { true; }

function type__ansi_4bit_colors() {
	case "$effect_name" in
		('reset') printf '\e[0m' ;;

		('color.black') printf '\e[30m' ;;
		('color.dark_gray') printf '\e[90m' ;;
		('color.light_gray') printf '\e[37m' ;;
		('color.white') printf '\e[97m' ;;

		('color.red') printf '\e[31m' ;;
		('color.green') printf '\e[32m' ;;
		('color.blue') printf '\e[34m' ;;
		('color.yellow') printf '\e[33m' ;;
		('color.magenta') printf '\e[35m' ;;
		('color.cyan') printf '\e[36m' ;;

		('color.bright_red') printf '\e[91m' ;;
		('color.bright_green') printf '\e[92m' ;;
		('color.bright_blue') printf '\e[94m' ;;
		('color.bright_yellow') printf '\e[93m' ;;
		('color.bright_magenta') printf '\e[95m' ;;
		('color.bright_cyan') printf '\e[96m' ;;
	esac
}

function type__ansi_8bit_colors() {
	type__ansi_4bit_colors "$1"
}

function type__common_24bit_true_color() {
	type__ansi_8bit_colors "$1"
}

function type__tput_ncurses_v6_or_above() {
	case "$1" in
		('reset') tput sgr0 ;;

		('color.black') tput setaf 0 ;;
		('color.dark_gray') tput setaf 8 ;;
		('color.light_gray') tput setaf 7 ;;
		('color.white') tput setaf 15 ;;

		('color.red') tput setaf 1 ;;
		('color.green') tput setaf 2 ;;
		('color.blue') tput setaf 4 ;;
		('color.yellow') tput setaf 3 ;;
		('color.magenta') tput setaf 5 ;;
		('color.cyan') tput setaf 6 ;;

		('color.bright_red') tput setaf 9 ;;
		('color.bright_green') tput setaf 10 ;;
		('color.bright_blue') tput setaf 12 ;;
		('color.bright_yellow') tput setaf 11 ;;
		('color.bright_magenta') tput setaf 13 ;;
		('color.bright_cyan') tput setaf 14 ;;

		('font.weight.bold') tput bold ;;

		('font.style.regular') tput ritm ;;
		('font.style.italic') tput sitm ;;
	esac
}

function type__common_ansi_full() {
	case "$1" in
		('font.weight.bold') printf '\e[1m' ;;

		('font.style.regular') printf '\e[23m' ;;
		('font.style.italic') printf '\e[3m' ;;

		(*) type__common_24bit_true_color "$1" ;;
	esac
}

#endregion

function determine_type() {
	if [[ "${NO_COLOR-}" != '' ]]; then
		printf 'none'
		return
	fi

	case "${TERM-}" in
		('xterm-kitty'|'xterm-ghostty')
			printf 'common_ansi_full'
			return
			;;
	esac

	if command -v tput > '/dev/null' && [[ "$(tput -V 2> '/dev/null')" =~ ^'ncurses '([1-9][0-9]*)('.'.*)?$ ]]; then
		local -i ncurses_major_version || return
		ncurses_major_version=${BASH_REMATCH[1]} || return

		if ((ncurses_major_version >= 6)); then
			local colors
			colors="$(tput colors 2> '/dev/null' || true)"

			if [[ "$colors" =~ ^[1-9][0-9]*$ ]]; then
				printf 'tput_ncurses_v6_or_above'
				return
			fi

			unset -v colors
		fi
	fi

	case "${COLORTERM-}" in
		('truecolor'|'24bit')
			printf 'common_24bit_true_color'
			return
			;;
	esac

	case "${TERM-}" in
		(*'-256color'|*'256')
			printf 'ansi_8bit_colors'
			return
			;;
		('xterm-color')
			printf 'ansi_4bit_colors'
			return
			;;
	esac

	printf 'none'
}

"type__$(determine_type)" "$effect_name"
