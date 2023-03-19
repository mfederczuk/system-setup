# shellcheck shell=sh

# SPDX-License-Identifier: CC0-1.0

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
_add_to_path back '/usr/local/sbin' \
                  '/usr/local/bin' \
                  '/usr/sbin' \
                  '/usr/bin' \
                  '/sbin' \
                  '/bin' \
                  '/usr/local/games' \
                  '/usr/games'

# at this point we should have access to `grep`, `id` and `cut`
export HOME="${HOME:-"$(\command grep -E "^[^:]*:[^:]*:$(id -u):$(\command id -g)" '/etc/passwd' | \command cut -d: -f6)"}"

# sorted from most to least priority
_add_to_path front '.bin' \
                   'node_modules/.bin' \
                   "$HOME/.local/bin" \
                   "$HOME/bin" \
                   "$HOME/bin/git" \
                   "$HOME/bin/repos" \
                   "$HOME/.dotnet/tools"

export PATH

unset -f _add_to_path

#endregion

export SHELL="${SHELL:-"$(\command grep -E "^[^:]*:[^:]*:$(id -u):$(id -g)" '/etc/passwd' | \command cut -d: -f7)"}"

export TMPDIR="${TMPDIR:-"/tmp"}"
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:-"/lib:/usr/lib:/usr/local/lib"}"

#region XDG base directories

# <https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html>

export XDG_DATA_HOME="${XDG_DATA_HOME:-"$HOME/.local/share"}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-"$HOME/.config"}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-"$HOME/.local/state"}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-"$HOME/.cache"}"

export XDG_DATA_DIRS="${XDG_DATA_DIRS:-"/usr/local/share/:/usr/share/"}"
export XDG_CONFIG_DIRS="${XDG_CONFIG_DIRS:-"/etc/xdg"}"

#endregion

#region editors

if command -v vim > '/dev/null'; then
	export EDITOR='vim'
	export VISUAL='vim'
elif command -v nano > '/dev/null'; then
	export EDITOR='nano'
	export VISUAL='nano'
fi

if command -v codium > '/dev/null'; then
	export GUI_EDITOR='codium -w'
fi

#endregion

#region programming languages / enviroments

# C & C++
export CC="${CC:-"cc"}"
export CXX="${CXX:-"c++"}"

# Android
if [ -d "$HOME/Android/Sdk" ]; then
	export ANDROID_SDK="${ANDROID_SDK:-"$HOME/Android/Sdk"}"
	export ANDROID_HOME="${ANDROID_HOME:-"$ANDROID_SDK"}"
fi

#region Node.js

if command -v node > '/dev/null'; then
	if [ -d '/usr/lib/node_modules' ]; then
		export NODE_PATH="${NODE_PATH:-"/usr/lib/node_modules"}"
	fi

	# TODO: these directories must be created manually
	export NODE_REPL_HISTORY="$XDG_STATE_HOME/node/repl_history"
	export TS_NODE_HISTORY="$XDG_STATE_HOME/ts-node/repl_history"
fi

#endregion

# .NET
export DOTNET_ROOT='/opt/dotnet'
export DOTNET_CLI_TELEMETRY_OPTOUT="${DOTNET_CLI_TELEMETRY_OPTOUT:-1}"

#endregion

export PAGER='less --ignore-case --quit-on-intr --LONG-PROMPT --RAW-CONTROL-CHARS --chop-long-lines -+X'

export SYSTEMD_PAGERSECURE='true'
export SYSTEMD_PAGER='less --quit-if-one-screen --ignore-case --quit-on-intr --LONG-PROMPT --RAW-CONTROL-CHARS --chop-long-lines -+X --file-size'

#region Git

if command -v git > '/dev/null'; then
	export GIT_PS1_SHOWDIRTYSTATE='yes'

	export GIT_COMPLETION_SHOW_ALL_COMMANDS='1' # exposes completion for plumbing commands
	export GIT_COMPLETION_SHOW_ALL='1' # exposes completion for rarely used options
fi

#endregion
