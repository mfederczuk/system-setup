#!/bin/sh
# -*- sh -*-
# vim: syntax=sh
# code: language=shellscript

# Written in 2022 by Michael Federczuk <federczuk.michael@protonmail.com>
#
# To the extent possible under law, the author(s) have dedicated all copyright
# and related and neighboring rights to this software to the public domain
# worldwide. This software is distributed without any warranty.
#
# You should have received a copy of the CC0 Public Domain Dedication along
# with this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.

# <https://gist.github.com/mfederczuk/14a6937d022d736a0a5fe7f8c2d9a2c2/de50316d4635e02a3c796b8f66c71fe78e03d064>

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


if ! command -v adb > '/dev/null'; then
	printf '%s: adb: program missing\n' "$argv0" >&2
	exit 27
fi


append_to_text() {
	if [ "${text+is_set}" = 'is_set' ]; then
		text="${text} "
	fi

	text="${text-}${1}"
}

append_to_text_from_stdin() {
	# command substituion `$(...)`` will trim any trailing newlines, so we additionally print an 'x' and  then remove it
	# manually
	stdin_contents="$(cat && printf x)"
	stdin_contents="${stdin_contents%x}"

	append_to_text "$stdin_contents"

	unset -v stdin_contents
}

append_to_text_from_x_selection() {
	if ! command -v xclip > '/dev/null'; then
		printf '%s: xclip: program missing\n' "$argv0" >&2
		exit 27
	fi

	x_selection="$(xclip -out -selection "$1" && printf x)"
	x_selection="${x_selection%x}"

	append_to_text "$x_selection"

	unset -v x_selection
}

process_opts=true

for arg in "$@"; do
	if $process_opts; then
		if [ "$arg" = '--' ]; then
			process_opts=false
			continue
		fi

		if printf '%s' "$arg" | head -n1 | grep -Eq '^--'; then
			opt="${arg#--}"

			case "$opt" in
				('stdin')                    append_to_text_from_stdin                   ;;
				('xa-primary')               append_to_text_from_x_selection 'primary'   ;;
				('xa-secondary')             append_to_text_from_x_selection 'secondary' ;;
				('xa-clipboard'|'clipboard') append_to_text_from_x_selection 'clipboard' ;;
				(*)
					printf '%s: --%s: invalid option\n' "$argv0" "$opt" >&2
					exit 5
					;;
			esac

			unset -v opt
			continue
		fi
	fi

	append_to_text "$arg"
done
unset -v arg

unset -v process_opts


if [ "${text+is_set}" != 'is_set' ]; then
	if [ -t 2 ]; then
		printf 'No arguments, reading from stdin...\n' >&2
	fi

	append_to_text_from_stdin
fi

unset -f append_to_text_from_x_selection \
         append_to_text_from_stdin \
         append_to_text


# escape sequences aren't available in single quote strings, so to escape single quotes themselves, we need to close the
# previous single quote string, escape a single quote, and then begin a new single quote string
text="$({ printf '%s' "$text" | sed -e s/\'/"'\\\\''"/g; } && printf x)"
text="${text%x}"

text="'$text'"

adb shell input text "$text"
