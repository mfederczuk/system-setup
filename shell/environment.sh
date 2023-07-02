# shellcheck shell=sh

# SPDX-License-Identifier: CC0-1.0

export PREFIX="${PREFIX:-"/data/data/com.termux/files/usr"}"

#region PATH setup

_add_to_path() {
	_add_to_path_local_side="$1"
	_add_to_path_local_tmp_path=''

	shift 1

	for _add_to_path_local_new_path in "$@"; do
		case "$PATH" in
			('') ;;
			# new dir already in path
			("$_add_to_path_local_new_path"|"$_add_to_path_local_new_path:"*|*":$_add_to_path_local_new_path:"*|*":$_add_to_path_local_new_path")
				continue
				;;
		esac

		# new dir not yet in path

		case "$_add_to_path_local_tmp_path" in
			# empty tmp PATH
			('') _add_to_path_local_tmp_path="$_add_to_path_local_new_path" ;;
			# new dir already in tmp PATH
			("$_add_to_path_local_new_path"|"$_add_to_path_local_new_path:"*|*":$_add_to_path_local_new_path:"*|*":$_add_to_path_local_new_path") ;;
			# new dir not yet in tmp PATH
			(*) _add_to_path_local_tmp_path="$_add_to_path_local_tmp_path:$_add_to_path_local_new_path" ;;
		esac
	done; unset -v _add_to_path_local_new_path

	if [ -n "$_add_to_path_local_tmp_path" ]; then
		case "$_add_to_path_local_side" in
			('front') PATH="$_add_to_path_local_tmp_path:$PATH" ;;
			('back')  PATH="$PATH:$_add_to_path_local_tmp_path" ;;
		esac
	fi

	unset -v _add_to_path_local_tmp_path _add_to_path_local_side
}

# sorted from most to least priority
_add_to_path back "$PREFIX/bin" \
                  "$PREFIX/local/bin"

export HOME="${HOME:-"$PREFIX/../home"}"

# sorted from most to least priority
_add_to_path front '.bin' \
                   'node_modules/.bin' \
                   "$HOME/.local/bin"

export PATH

unset -f _add_to_path

#endregion

export SHELL="${SHELL:-"$PREFIX/bin/bash"}"

export TMPDIR="${TMPDIR:-"$PREFIX/tmp"}"
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:-"/lib:/usr/lib:$PREFIX/lib:$PREFIX/local/lib"}"

#region XDG base directories

# <https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html>

export XDG_DATA_HOME="${XDG_DATA_HOME:-"$HOME/.local/share"}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-"$HOME/.config"}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-"$HOME/.local/state"}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-"$HOME/.cache"}"

export XDG_DATA_DIRS="${XDG_DATA_DIRS:-"$PREFIX/local/share/:$PREFIX/share/"}"
export XDG_CONFIG_DIRS="${XDG_CONFIG_DIRS:-"$PREFIX/etc/xdg"}"

#endregion

#region editors

if command -v vim > '/dev/null'; then
	export EDITOR='vim'
	export VISUAL='vim'
elif command -v nano > '/dev/null'; then
	export EDITOR='nano'
	export VISUAL='nano'
fi

#endregion

#region programming languages / environments

# C & C++
export CC="${CC:-"cc"}"
export CXX="${CXX:-"c++"}"

#region Node.js

if command -v node > '/dev/null'; then
	# TODO: these directories must be created manually
	export NODE_REPL_HISTORY="$XDG_STATE_HOME/node/repl_history"
	export TS_NODE_HISTORY="$XDG_STATE_HOME/ts-node/repl_history"
fi

#endregion

#endregion

export PAGER='less --ignore-case --quit-on-intr --LONG-PROMPT --RAW-CONTROL-CHARS --chop-long-lines -+X'

#region Git

if command -v git > '/dev/null'; then
	export GIT_PS1_SHOWDIRTYSTATE='yes'

	export GIT_COMPLETION_SHOW_ALL_COMMANDS='1' # exposes completion for plumbing commands
	export GIT_COMPLETION_SHOW_ALL='1' # exposes completion for rarely used options
fi

#endregion
