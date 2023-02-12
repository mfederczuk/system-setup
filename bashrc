# shellcheck shell=bash
# -*- sh -*-
# vim: syntax=sh
# code: language=shellscript

# only continue if running interactively
if [[ "$-" != *i* ]]; then
	return
fi

#region history setup

export HISTFILE="$XDG_STATE_HOME/bash/history"

shopt -s histappend

export HISTCONTROL=ignoreboth # same as 'ignorespace' and 'ignoredups'

export HISTTIMESTAMP='[%Y-%m-%d %M:%H:%S] '

export HISTSIZE=$((2**16))
export HISTFILESIZE=$((HISTSIZE * 2)) # double to account for the timestamp line

#endregion

shopt -s globstar
shopt -u sourcepath # disables PATH lookup for the `.` (dot) and `source` builtins

#region sourcing other bash files

if [ -f "$HOME/.bash_aliases" ]; then
	# shellcheck source=bash_aliases
	. "$HOME/.bash_aliases"
fi

if [ -f "$HOME/.bash_funcs" ]; then
	# shellcheck source=bash_funcs
	. "$HOME/.bash_funcs"
fi

declare __bashrc__completion_file_pathname

for __bashrc__completion_file_pathname in "$HOME/"{'completions/','.local/etc/bash_completion.d/'}*'.bash'{,'-completion'}; do
	if [ -f "$__bashrc__completion_file_pathname" ]; then
		# shellcheck disable=1090
		. "$__bashrc__completion_file_pathname"
	fi
done

unset -v __bashrc__completion_file_pathname

#endregion
