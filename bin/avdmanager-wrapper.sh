#!/bin/sh
# -*- sh -*-
# vim: syntax=sh
# code: language=shellscript

# Copyright (c) 2023 Michael Federczuk
# SPDX-License-Identifier: MPL-2.0 AND Apache-2.0

# cSpell:ignore avdmanager

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

#region checking ANDROID_HOME

if [ -z "${ANDROID_HOME-}" ]; then
	printf '%s: environment variable ANDROID_HOME must not be unset or empty\n' "$argv0" >&2
	exit 48
fi

#endregion

#region checking avdmanager executable file

avdmanager_pathname="$ANDROID_HOME/tools/bin/avdmanager"
readonly avdmanager_pathname

if [ ! -e "$avdmanager_pathname" ]; then
	printf '%s: %s: no such file\n' "$argv0" "$avdmanager_pathname" >&2
	exit 24
fi
if [ ! -f "$avdmanager_pathname" ]; then
	printf '%s: %s: not a file\n' "$argv0" "$avdmanager_pathname" >&2
	exit 26
fi
if [ ! -x "$avdmanager_pathname" ]; then
	printf '%s: %s: permission denied: executable permissions missing\n' "$argv0" "$avdmanager_pathname" >&2
	exit 77
fi

#endregion

#region searching for java 8 runtime

try_set_java_home() {
	_try_set_java_home__java_home='' || return

	for _try_set_java_home__dirname in "$@"; do
		_try_set_java_home__java_home="/usr/lib/jvm/$_try_set_java_home__dirname" || return
		unset -v _try_set_java_home__dirname || return

		if [ -d "$_try_set_java_home__java_home" ] && [ -x "$_try_set_java_home__java_home/bin/java" ]; then
			break || return
		fi

		_try_set_java_home__java_home='' || return
	done

	if [ -n "$_try_set_java_home__java_home" ]; then
		JAVA_HOME="$_try_set_java_home__java_home" || return
	fi

	unset -v _try_set_java_home__java_home
}

unset -v JAVA_HOME

try_set_java_home 'java-1.8.0'         'java-8'         \
                   'jre-1.8.0'          'jre-8'         \
                  'java-1.8.0-openjdk' 'java-8-openjdk' \
                   'jre-1.8.0-openjdk'  'jre-8-openjdk'

if [ -z "${JAVA_HOME-}" ]; then
	case "$(uname -m)" in
		('x86_64'|'amd64')
			try_set_java_home 'java-1.8.0-openjdk-x86_64' 'java-8-openjdk-x86_64' \
			                   'jre-1.8.0-openjdk-x86_64'  'jre-8-openjdk-x86_64' \
			                  'java-1.8.0-openjdk-amd64'  'java-8-openjdk-amd64'  \
			                   'jre-1.8.0-openjdk-amd64'   'jre-8-openjdk-amd64'
			;;
		('aarch64'|'arm64')
			try_set_java_home 'java-1.8.0-openjdk-arm64'   'java-8-openjdk-arm64'   \
			                   'jre-1.8.0-openjdk-arm64'    'jre-8-openjdk-arm64'   \
			                  'java-1.8.0-openjdk-aarch64' 'java-8-openjdk-aarch64' \
			                   'jre-1.8.0-openjdk-aarch64'  'jre-8-openjdk-aarch64'
			;;
	esac
fi

if [ -z "${JAVA_HOME-}" ]; then
	printf '%s: could not find a Java 8 runtime environment\n' "$argv0" >&2
	exit 32
fi

unset -f try_set_java_home

export JAVA_HOME

#endregion

{
	printf -- '--------------------------------------------------------------------------------\n'
	printf "Using JRE '%s'\\n\\n" "$JAVA_HOME"
	"$JAVA_HOME/bin/java" -version # `java -version` should already write to stderr, but better safe than sorry i guess
	printf -- '--------------------------------------------------------------------------------\n'
} >&2

"$avdmanager_pathname" "$@"
