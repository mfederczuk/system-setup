# shellcheck shell=bash
# -*- sh -*-
# vim: syntax=bash
# code: language=shellscript

# SPDX-License-Identifier: CC0-1.0

if [ -f "$HOME/.environment.sh" ]; then
	# shellcheck source=shell/environment.sh
	. "$HOME/.environment.sh"
fi

# only continue if running interactively
if [[ "$-" != *i* ]]; then
	return
fi

if [ -f '/etc/bashrc' ]; then
	. '/etc/bashrc'
fi

#region history setup

# TODO: this directory must be created manually
declare HISTFILE="$XDG_STATE_HOME/bash/history"

shopt -s histappend

declare HISTCONTROL=ignoreboth # same as 'ignorespace' and 'ignoredups'

declare HISTTIMEFORMAT='[%Y-%m-%d %M:%H:%S] '

declare HISTSIZE=$((2**16))
declare HISTFILESIZE=$((HISTSIZE * 2)) # double to account for the timestamp line

#endregion

shopt -s globstar
shopt -u sourcepath # disables PATH lookup for the `.` (dot) and `source` builtins

if command -v dircolors > '/dev/null'; then
	eval "$(dircolors -b)"
fi

if command -v git > '/dev/null'; then
	if [ -f '/usr/share/git-core/contrib/completion/git-prompt.sh' ]; then
		. '/usr/share/git-core/contrib/completion/git-prompt.sh'
	fi

	# pre-sourcing git's bash completion so that `__git_complete` is available
	if [ -f '/usr/share/bash-completion/completions/git' ]; then
		. '/usr/share/bash-completion/completions/git'
	fi
fi

#region sourcing other bash files

if [ -f "$XDG_CONFIG_HOME/bash/funcs.bash" ]; then
	# shellcheck source=shell/shells/bash/funcs.bash
	. "$XDG_CONFIG_HOME/bash/funcs.bash"
fi

if [ -f "$XDG_CONFIG_HOME/bash/aliases.bash" ]; then
	# shellcheck source=shell/shells/bash/aliases.bash
	. "$XDG_CONFIG_HOME/bash/aliases.bash"
fi

if [ -f "$XDG_CONFIG_HOME/bash/secret.bash" ]; then
	# shellcheck disable=1091
	. "$XDG_CONFIG_HOME/bash/secret.bash"
fi

declare __bashrc__completion_file_pathname

# youtube-dl installs its completions script into '$HOME/.local/etc/bash_completion.d'
# <https://github.com/ytdl-org/youtube-dl/blob/2021.12.17/Makefile#L25-L26>
for __bashrc__completion_file_pathname in {"$XDG_CONFIG_HOME/bash/completions/","$HOME/.local/etc/bash_completion.d"}*'.bash'{,'-completion'}; do
	if [ -f "$__bashrc__completion_file_pathname" ]; then
		# shellcheck disable=1090
		. "$__bashrc__completion_file_pathname"
	fi
done

unset -v __bashrc__completion_file_pathname

#endregion

# shellcheck disable=2034
if command -v git > '/dev/null'; then
	declare git_empty_blob_hash
	git_empty_blob_hash="$(git --no-pager hash-object -t blob '/dev/null')"

	declare git_empty_tree_hash
	git_empty_tree_hash="$(git --no-pager hash-object -t tree '/dev/null')"
fi
