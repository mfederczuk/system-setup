# shellcheck shell=bash
# -*- sh -*-
# vim: syntax=bash
# code: language=shellscript

# SPDX-License-Identifier: CC0-1.0

if [ -f "$HOME/.environment.sh" ]; then
	# shellcheck source=../../shell/environment.sh
	. "$HOME/.environment.sh"
fi

# only continue if running interactively
if [[ "$-" != *i* ]]; then
	return
fi

#% if (operating_system != "android-termux") {
	#% if (system_bash_rc_file_path != "") {
		if [ -f '%{system_bash_rc_file_path}' ]; then
			. '%{system_bash_rc_file_path}'
		fi

	#% }
#% } else {
	if [ -f "$PREFIX/etc/bash.bashrc" ]; then
		. "$PREFIX/etc/bash.bashrc"
	fi

#% }
#region history setup

#% mkdir "$XDG_STATE_HOME/bash/history"
declare HISTFILE="$XDG_STATE_HOME/bash/history"

shopt -s histappend

declare HISTCONTROL=ignoreboth # same as 'ignorespace' and 'ignoredups'

declare HISTTIMEFORMAT='[%Y-%m-%d %M:%H:%S] '

declare HISTSIZE=$((2**16))
declare HISTFILESIZE=$((HISTSIZE * 2)) # double to account for the timestamp line

#endregion

shopt -s globstar
shopt -u sourcepath # disables PATH lookup for the `.` (dot) and `source` builtins

#region ls colors

if command -v dircolors > '/dev/null'; then
	eval "$(dircolors -b)"
fi

# support for JPEG XL files
if [[ ! "${LS_COLORS-}" =~ (^|':')'*.jxl='[^':']*(':'|$) ]] && \
	[[ "${LS_COLORS-}" =~ (^|':')'*.jp'('e')?'g='([^':']+)(':'|$) ]]; then

	declare __bashrc__jxl_ls_color_entry
	__bashrc__jxl_ls_color_entry="*.jxl=${BASH_REMATCH[3]}"

	if [[ "$LS_COLORS" =~ ':'$ ]]; then
		__bashrc__jxl_ls_color_entry+=':'
	else
		__bashrc__jxl_ls_color_entry=":$__bashrc__jxl_ls_color_entry"
	fi

	LS_COLORS+="$__bashrc__jxl_ls_color_entry"

	unset -v __bashrc__jxl_ls_color_entry
fi

#endregion

if command -v git > '/dev/null'; then
	#% if (operating_system != "android-termux") {
		#% if (system_git_bash_prompt_file_path != "") {
			if [ -f '%{system_git_bash_prompt_file_path}' ]; then
				. '%{system_git_bash_prompt_file_path}'
			fi

		#% }
	#% } else {
		if [ -f "$PREFIX/etc/bash_completion.d/git-prompt.sh" ]; then
			. "$PREFIX/etc/bash_completion.d/git-prompt.sh"
		fi

	#% }
	# pre-sourcing git's bash completion so that `__git_complete` is available
	#% if (operating_system != "android-termux") {
		if [ -f '/usr/share/bash-completion/completions/git' ]; then
			. '/usr/share/bash-completion/completions/git'
		fi
	#% } else {
		if [ -f "$PREFIX/share/bash-completion/completions/git" ]; then
			. "$PREFIX/share/bash-completion/completions/git"
		fi
	#% }
fi

#region sourcing other bash files

if [ -f "$XDG_CONFIG_HOME/bash/funcs.bash" ]; then
	# shellcheck source=funcs.bash
	. "$XDG_CONFIG_HOME/bash/funcs.bash"
fi

if [ -f "$XDG_CONFIG_HOME/bash/aliases.bash" ]; then
	# shellcheck source=aliases.bash
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

#% if (operating_system == "android-termux") {
	#region prompt variables

	function __bashrc__set_ps_vars() {
		#region terminal effect variables

		#region literals

		local fx_reset          || return
		local fx_lit_bold       || return
		local fx_lit_green      || return
		local fx_lit_lightgreen || return
		local fx_lit_blue       || return
		local fx_lit_lightblue  || return
		local fx_lit_cyan       || return
		local fx_lit_lightcyan  || return

		fx_reset=''          || return
		fx_lit_bold=''       || return
		fx_lit_green=''      || return
		fx_lit_lightgreen='' || return
		fx_lit_blue=''       || return
		fx_lit_lightblue=''  || return
		fx_lit_cyan=''       || return
		fx_lit_lightcyan=''  || return

		if command -v is_color_supported > '/dev/null' && is_color_supported 2; then
			fx_reset="\\[$(tput sgr0)\\]"              || fx_reset=''                       || return
			fx_lit_bold="\\[$(tput bold)\\]"           || fx_lit_bold=''                    || return
			fx_lit_green="\\[$(tput setaf 2)\\]"       || fx_lit_green="$fx_reset"          || return
			fx_lit_lightgreen="\\[$(tput setaf 10)\\]" || fx_lit_lightgreen="$fx_lit_green" || return
			fx_lit_blue="\\[$(tput setaf 4)\\]"        || fx_lit_blue="$fx_reset"           || return
			fx_lit_lightblue="\\[$(tput setaf 12)\\]"  || fx_lit_lightblue="$fx_lit_blue"   || return
			fx_lit_cyan="\\[$(tput setaf 6)\\]"        || fx_lit_cyan="$fx_reset"           || return
			fx_lit_lightcyan="\\[$(tput setaf 14)\\]"  || fx_lit_lightcyan="$fx_lit_cyan"   || return
		fi

		readonly fx_lit_lightcyan  || return
		readonly fx_lit_cyan       || return
		readonly fx_lit_lightblue  || return
		readonly fx_lit_blue       || return
		readonly fx_lit_lightgreen || return
		readonly fx_lit_green      || return
		readonly fx_lit_bold       || return
		readonly fx_reset          || return

		#endregion

		#region semantics

		local fx_sem_ps2           || return
		local fx_sem_timestamp     || return
		local fx_sem_timestamp_ps0 || return
		local fx_sem_timestamp_ps1 || return
		local fx_sem_cwd           || return
		local fx_sem_gitrepoinfo   || return
		local fx_sem_promptchar    || return

		fx_sem_ps2="${fx_lit_lightblue}${fx_lit_bold}" || return

		fx_sem_timestamp="${fx_lit_lightgreen}" || return
		fx_sem_timestamp_ps0="$fx_sem_timestamp" || return
		fx_sem_timestamp_ps1="$fx_sem_timestamp" || return

		fx_sem_cwd="${fx_lit_lightblue}${fx_lit_bold}" || return

		fx_sem_gitrepoinfo="${fx_lit_lightcyan}${fx_lit_bold}" || return

		fx_sem_promptchar="${fx_lit_lightblue}${fx_lit_bold}" || return

		readonly fx_sem_promptchar    || return
		readonly fx_sem_gitrepoinfo   || return
		readonly fx_sem_cwd           || return
		readonly fx_sem_timestamp_ps1 || return
		readonly fx_sem_timestamp_ps0 || return
		readonly fx_sem_timestamp     || return
		readonly fx_sem_ps2           || return

		#endregion

		#endregion

		#region building prompt strings

		unset -v PS2 PS1 PS0 || return
		declare -g PS0 PS1 PS2 || return

		PS0="${fx_sem_timestamp_ps0}[\\t]${fx_reset}\\n" || return
		PS2=" ${fx_sem_ps2}>${fx_reset} " || return

		PS1='' || return

		# terminal title
		PS1+="\\[\\033]0;\u@\H:\w\\007\\]" || return

		PS1+="${fx_reset}\\n" || return

		# timestamp
		PS1+="${fx_sem_timestamp_ps1}[\\t]${fx_reset}" || return

		PS1+='\n' || return

		# current working directory
		PS1+="${fx_sem_cwd}\\w${fx_reset}" || return

		# git repository info
		if command -v git > '/dev/null' && command -v __git_ps1 > '/dev/null'; then
			PS1+="${fx_sem_gitrepoinfo}\$(__git_ps1 ' (%s)')${fx_reset}" || return
		fi

		PS1+=' ' || return

		# prompt character
		PS1+="${fx_sem_promptchar}\\\$${fx_reset}" || return

		PS1+=' ' || return

		#endregion
	}

	__bashrc__set_ps_vars

	unset -f __bashrc__set_ps_vars

	#endregion

#% }
# shellcheck disable=2034
if command -v git > '/dev/null'; then
	declare git_empty_blob_hash
	git_empty_blob_hash="$(git --no-pager hash-object -t blob '/dev/null')"

	declare git_empty_tree_hash
	git_empty_tree_hash="$(git --no-pager hash-object -t tree '/dev/null')"
fi
#% if (operating_system == "android-termux") {

	# This is required to make Git commit GPG signing work on Termux (see <https://superuser.com/a/1407685/1506991> and
	# the man page gpg-agent(1))
	GPG_TTY="$(tty)"
	export GPG_TTY
#% }
