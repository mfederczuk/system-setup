# shellcheck shell=sh
# -*- sh -*-
# vim: syntax=sh
# code: language=shellscript

umask 022

#region environment variables setup

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
                   "$HOME/bin" \
                   "$HOME/bin/git" \
                   "$HOME/bin/repos" \
                   "$HOME/.local/bin" \
                   "$HOME/.local/lib/nodejs/bin" \
                   "$HOME/.cargo/bin" \
                   "$HOME/Android/Sdk/cmdline-tools/latest/bin" \
                   "$HOME/.sdkman/candidates/kotlin/current/bin" \
                   "$HOME/.sdkman/candidates/gradle/current/bin" \
                   '/usr/local/lib/kotlin-native-linux/bin' \
                   "$HOME/.local/lib/flutter/bin" \
                   "$HOME/go/bin" \
                   "$HOME/.dotnet/tools"

export PATH

#endregion

export SHELL="${SHELL:-"$(\command grep -E "^[^:]*:[^:]*:$(id -u):$(id -g)" '/etc/passwd' | \command cut -d: -f7)"}"

export TMPDIR="${TMPDIR:-"/tmp"}"
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:-"/lib:/usr/lib:/usr/local/lib"}"

# XDG base directory environment variables <https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html>

export XDG_DATA_HOME="${XDG_DATA_HOME:-"$HOME/.local/share"}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-"$HOME/.config"}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-"$HOME/.local/state"}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-"$HOME/.cache"}"

export XDG_DATA_DIRS="${XDG_DATA_DIRS:-"/usr/local/share/:/usr/share/"}"
export XDG_CONFIG_DIRS="${XDG_CONFIG_DIRS:-"/etc/xdg"}"

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

# Node.JS
if [ -d '/usr/lib/node_modules' ]; then
	export NODE_PATH="${NODE_PATH:-"/usr/lib/node_modules"}"
fi

# .NET
export DOTNET_ROOT='/opt/dotnet'
export DOTNET_CLI_TELEMETRY_OPTOUT="${DOTNET_CLI_TELEMETRY_OPTOUT:-1}"

#endregion

#endregion

#region shell specific runcoms

if [ -n "$BASH_VERSION" ]; then
	if [ -f "$HOME/.bashrc" ]; then
		# shellcheck source=bashrc
		. "$HOME/.bashrc"
	fi
fi

if [ -n "$ZSH_VERSION" ]; then
	if [ -f "$HOME/.zshrc" ]; then
		# shellcheck disable=1091
		. "$HOME/.zshrc"
	fi
fi

if [ -n "$FISH_VERSION" ]; then
	if [ -f "$HOME/.fishrc" ]; then
		# shellcheck disable=1091
		. "$HOME/.fishrc"
	fi
fi

#endregion

#region cleaning up environment variable PATH

# squeezing colons
if \command printf '%s' "$PATH" | \command grep -Eq '::'; then
	PATH="$({ \command printf '%s' "$PATH" | \command tr -s ':'; } && \command printf x)"
	PATH="${PATH%x}"
fi

# removing optional leading & trailing colons
PATH="${PATH#:}"
PATH="${PATH%:}"

export PATH

#endregion
