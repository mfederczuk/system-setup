#!/bin/sh
# -*- sh -*-
# vim: set syntax=sh
# code: language=shellscript

# Copyright (c) 2022 Michael Federczuk
# SPDX-License-Identifier: MPL-2.0 AND Apache-2.0

# <https://github.com/mfederczuk/ktlint-install/blob/v0.3.0/ktlint-install>

set -o errexit
set -o nounset

# enabling POSIX-compliant behavior for GNU programs
export POSIXLY_CORRECT=yes POSIX_ME_HARDER=yes

command_exists() {
	command -v "$1" > '/dev/null'
}

starts_with() {
	# not using `grep` because it works line-by-line; if the prefix substring ($2) would appear after a newline in the
	# middle of the base string ($1), grep would falsely match
	test "${1#"$2"}" != "$1"
}

argv0() {
	if [ "${0#/}" != "$0" ]; then
		printf '%s' "$(basename "$0")"
	else
		printf '%s' "$0"
	fi
}

mktemp_portable() {
	# i was kinda shook that mktemp isn't part of any POSIX specification
	printf 'mkstemp(%s)' "$1" | m4
}

try_as_root() {
	if command_exists doas; then
		# preferring `doas` because it's leaner and meaner and better suited for single-user systems than `sudo`
		doas "$@"
	elif command_exists sudo; then
		sudo "$@"
	else
		"$@"
	fi
}

log() {
	echo "$1" >&2
}
errlog() {
	log "$(argv0): $1"
}

# region args

print_usage() {
	log "usage: $(argv0) ( <version> | latest | --help )"
}

print_help() {
	print_usage
	{
		echo '    Downloads & installs ktlint onto the system.'
		echo
		echo '    Options:'
		echo "          --dry-run      don't download and install anything"
		echo '          --prefer-curl  prefer using curl as downloading command'
		echo '          --prefer-wget  prefer using Wget as downloading command (default)'
		echo '      -h, --help         display this summary and exit'
		echo '      -V, --version      display version and legal information and exit'
		echo
		echo "GitHub repository: <https://github.com/mfederczuk/ktlint-install>"
	} >&2
}

print_version_info() {
	{
		echo 'ktlint-install 0.3.0'
		echo
		echo 'Copyright (C) 2022 Michael Federczuk'
		echo
		echo '    License MPL-2.0: Mozilla Public License 2.0 <https://www.mozilla.org/en-US/MPL/2.0/>'
		echo '            AND'
		echo '    License Apache-2.0: Apache License 2.0 <https://www.apache.org/licenses/LICENSE-2.0>'
		echo
		echo 'This is free software: you are free to change and redistribute it.'
		echo 'There is NO WARRANTY, to the extent permitted by law.'
		echo
		echo 'Written by Michael Federczuk.'
	} >&2
}

opt_dry_run=false
opt_preferred_dl_cmd='wget'

excess_argc=0
first_invalid_opt=''
process_opts=true

for arg in "$@"; do
	if $process_opts && [ "$arg" = '--' ]; then
		process_opts=false
		continue
	fi

	if $process_opts && printf '%s' "$arg" | grep -Eq '^--'; then
		opt_word="${arg#--}"

		case "$opt_word" in
			('help')
				print_help
				exit
				;;
			('version')
				print_version_info
				exit
				;;
			('dry-run')
				opt_dry_run=true
				;;
			('prefer-curl')
				opt_preferred_dl_cmd='curl'
				;;
			('prefer-wget')
				opt_preferred_dl_cmd='wget'
				;;
			(*)
				if [ -z "$first_invalid_opt" ]; then
					first_invalid_opt="--$opt_word"
				fi
				;;
		esac

		unset -v opt_word
		continue
	fi

	if $process_opts && printf '%s' "$arg" | grep -Eq '^-'; then
		opt_chars="${arg#-}"

		while [ ${#opt_chars} -gt 0 ]; do
			opt_char="${opt_chars%"${opt_chars#?}"}"

			case "$opt_char" in
				('h')
					print_help
					exit
					;;
				('V')
					print_version_info
					exit
					;;
				(*)
					if [ -z "$first_invalid_opt" ]; then
						first_invalid_opt="-$opt_char"
					fi
					;;
			esac

			opt_chars="${opt_chars#"$opt_char"}"
			unset -v opt_char
		done

		unset -v opt_chars
		continue
	fi

	if [ "${requested_version_spec-not_set}" = 'not_set' ]; then
		if [ "$arg" != 'latest' ]; then
			requested_version_spec="exact:$arg"
		else
			requested_version_spec="latest:"
		fi

		continue
	fi

	excess_argc=$((excess_argc + 1))
done; unset -v arg

readonly requested_version_spec opt_dry_run opt_preferred_dl_cmd
unset -v process_opts
unset -f print_version_info print_help

if [ -n "$first_invalid_opt" ]; then
	errlog "$first_invalid_opt: invalid option"
	print_usage
	exit 5
fi
unset -v first_invalid_opt

if [ "${requested_version_spec-not_set}" = 'not_set' ]; then
	errlog 'missing argument: ( <version> | latest )'
	print_usage
	exit 3
fi

if [ -z "${requested_version_spec%exact:}" ]; then
	if [ $excess_argc -eq 0 ]; then
		errlog 'argument must not be empty'
	else
		errlog 'argument 1: must not be empty'
	fi
	print_usage
	exit 9
fi

if [ $excess_argc -gt 0 ]; then
	errlog "too many arguments: $excess_argc"
	print_usage
	exit 4
fi

unset -v excess_argc
unset -f print_usage

if starts_with "$requested_version_spec" 'exact:' &&
   ! printf '%s' "${requested_version_spec#exact:}" | grep -Eq '^[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+$'; then

	log "The version '${requested_version_spec#exact:}' doesn't seem correct (MAJOR.MINOR.PATCH)"
	printf 'Do you want to continue? [y/N] ' >&2

	read -r ans
	case "$ans" in
		(['yY']*)
			# continue
			;;
		(*)
			log 'Aborted.'
			exit 32
			;;
	esac

	unset -v ans
fi

# endregion

# region check download commands

available_dl_cmds=''

if command_exists wget; then available_dl_cmds="$available_dl_cmds(wget)"; fi
if command_exists curl; then available_dl_cmds="$available_dl_cmds(curl)"; fi

readonly available_dl_cmds

if [ -z "$available_dl_cmds" ]; then
	errlog 'wget or curl missing'
	exit 48
fi


case "$available_dl_cmds" in
	(*"($opt_preferred_dl_cmd)"*)
		dl_cmd="$opt_preferred_dl_cmd"
		;;
	(*'(wget)'*) dl_cmd='wget' ;;
	(*'(curl)'*) dl_cmd='curl' ;;
esac

readonly dl_cmd


case "$dl_cmd" in
	('wget')
		download_file() {
			wget -O "$2" -- "$1"
		}
		;;
	('curl')
		download_file() {
			curl -Lo "$2" -- "$1"
		}
		;;
esac

# endregion

# region determine source URL

if starts_with "$requested_version_spec" 'exact:'; then
	version_to_install="${requested_version_spec#exact:}"
elif starts_with "$requested_version_spec" 'latest:'; then
	case "$available_dl_cmds" in
		(*'(curl)'*)
			# ok
			;;
		(*)
			errlog 'curl: program missing'
			exit 27
			;;
	esac

	response="$(curl -sSX HEAD -w '%{http_code}\n%{redirect_url}' 'https://github.com/pinterest/ktlint/releases/latest')"

	response_code="$(printf '%s' "$response" | head -n1)"
	if ! printf '%s' "$response_code" | grep -Eq '^3[0-9][0-9]$'; then
		errlog 'could not determine the latest ktlint version'
		exit 49
	fi
	unset -v response_code

	location_url="$(printf '%s' "$response" | tail -n1)"
	version_to_install="$(printf '%s' "$location_url" | sed s%'^https://github.com/[a-zA-Z0-9_-][a-zA-Z0-9_-]*/ktlint/releases/tag/\([^/][^/]*\)$'%'\1'%)"

	if [ -z "$version_to_install" ]; then
		errlog 'could not determine the latest ktlint version'
		exit 49
	fi

	unset -v location_url response
else
	errlog "emergency stop: wrong format for 'requested_version_spec' variable: $requested_version_spec"
	exit 123
fi

readonly source_url="https://github.com/pinterest/ktlint/releases/download/$version_to_install/ktlint"
unset -v version_to_install

# endregion

# region downloading and moving binary into correct position

tmp_file='ktlint'
if [ -e "$tmp_file" ]; then
	if ! $opt_dry_run; then
		tmp_file="$(mktemp_portable "$tmp_file.")"
	else
		log "file 'ktlint' exists; would create a temporary file to download to"
		tmp_file='[[temporary_file]]'
	fi
fi
readonly tmp_file

if ! target_file="$(command -v ktlint)"; then
	if [ -n "${HOME-}" ] &&
	   [ -d "$HOME/.local" ] &&
	   { [ ! -e "$HOME/.local/bin" ] || [ -d "$HOME/.local/bin" ]; }; then

		target_file="$HOME/.local/bin/ktlint"
	else
		target_file='/usr/local/bin/ktlint'
	fi
fi
readonly target_file

if [ -e "$target_file" ] && [ ! -f "$target_file" ]; then
	errlog "$target_file: not a regular file"
	exit 26
fi

target_parent_dir="$(dirname "$target_file")"
readonly target_parent_dir

if ! $opt_dry_run; then
	download_file "$source_url" "$tmp_file"
	chmod +x "$tmp_file"
else
	if [ "$tmp_file" != '[[temporary_file]]' ]; then
		log "would use '$dl_cmd' to download '$source_url' into '$tmp_file'"
	else
		log "would use '$dl_cmd' to download '$source_url' into the temporary file"
	fi
fi

if [ -w "$target_parent_dir" ]; then
	# we don't need to check for write access to the target file here, since replacing an entire file (changing
	# the inode) only requires directory write access

	if ! $opt_dry_run; then
		mv -f "$tmp_file" "$target_file"
	else
		if [ "$tmp_file" != '[[temporary_file]]' ]; then
			log "would move '$tmp_file' to '$target_file'"
		else
			log "would move the temporary file to '$target_file'"
		fi
	fi
	exit
fi

if [ -w "$target_file" ]; then
	# even though the current user has write access to the target file, the user DOESN'T have write access to the parent
	# directory of the target file, which means that using `mv` is not possible, since it's replacing the entire file,
	# which counts as modifying the directory -- which we don't have access to, so we need to use `dd` to write to the
	# target file, without modyfing the directory

	if ! $opt_dry_run; then
		dd if="$tmp_file" of="$target_file"
	else
		if [ "$tmp_file" != '[[temporary_file]]' ]; then
			log "would write '$tmp_file' to '$target_file'"
		else
			log "would write the temporary file to '$target_file'"
		fi
	fi
	exit
fi

# last ditch effort is trying to execute as root
# if neither `doas` or `sudo` exist, it'll execute the command with neither - which is *very* high likely going to fail,
# but at least `mv` should print a proper error
if ! $opt_dry_run; then
	try_as_root mv "$tmp_file" "$target_file"
else
	if [ "$tmp_file" != '[[temporary_file]]' ]; then
		log "would try to move '$tmp_file' to '$target_file' as root"
	else
		log "would try to move the temporary file to '$target_file' as root"
	fi
fi

# endregion
