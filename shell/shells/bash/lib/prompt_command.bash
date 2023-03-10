# Copyright (c) 2023 Michael Federczuk
# SPDX-License-Identifier: MPL-2.0 AND Apache-2.0

# TODO: i really love this prompt, but having this all done by bash is starting to become noticeable in terms of speed
#       (in preview mode, the prompt is shown pretty much instantly, meanwhile the non-preview prompt takes
#        a few milliseconds to display)
#       moving this all to an external program written in C or C++ would help very much, though
#       the directory environment variables will probably be a bit more complicated to pull off, and i'd like to keep
#       the config variables (e.g.: `DIR_ENV_VARS_ENABLED`, `PREVIEW_MODE_ENABLED`, ...) as non-environment variables,
#       which means that we'd need to pass those values in from bash to the external program.
#       something like this:
#
#               eval "$(external_prompt_command bash init)"
#
#       could set up the PROMPT_COMMAND variable exactly how it is needed:
#
#               function ___external_prompt_command__bash__prompt_command() {
#               	local -ir prev_cmd_exc=$? || return;
#
#               	if ! command -v external_prompt_command > '/dev/null'; then
#               		printf '%s: external_prompt_command: program missing\n' "${FUNCNAME[0]}" >&2;
#               		return 27;
#               	fi
#
#               	local s || return;
#               	s="$(external_prompt_command bash prompt prev_cmd_exc=$prev_cmd_exc \
#               	                                         dir_env_vars_enabled="${DIR_ENV_VARS_ENABLED-}" dir_env_vars="${DIR_ENV_VARS_FILENAME-}" \
#               	                                         preview_mode_enabled="${PREVIEW_MODE_ENABLED-}" \
#               	                                         dir_info_enabled="${DIR_INFO_ENABLED-}" dir_info_filename="${DIR_INFO_FILENAME-}" dir_info_line_prefix="${DIR_INFO_LINE_PREFIX-}")" || return;
#               	readonly s || return;
#
#               	eval "$s";
#               }
#
#               if declare -p PROMPT_COMMAND &> '/dev/null'; then
#               	if [[ ! "$(declare -p PROMPT_COMMAND)" =~ ^'declare -'([^'a']*'a'[^'a']*)+' ' ]]; then
#               		declare ___external_prompt_command__bash__tmp;
#               		___external_prompt_command__bash__tmp="$PROMPT_COMMAND";
#
#               		unset -v PROMPT_COMMAND;
#
#               		declare -a PROMPT_COMMAND;
#               		PROMPT_COMMAND=("$___external_prompt_command__bash__tmp");
#
#               		unset -v ___external_prompt_command__bash__tmp;
#               	fi
#               else
#               	declare -a PROMPT_COMMAND;
#               	PROMPT_COMMAND=();
#               fi
#
#               PROMPT_COMMAND+=(___external_prompt_command__bash__prompt_command);

#region helper functions

function __dotfiles_bash_funcs_prompt_command__escape_for_ps() {
	local str || return
	str="$1" || return
	readonly str || return

	local escaped_str || return
	escaped_str="$str" || return

	# shellcheck disable=1003
	escaped_str="${escaped_str//'\'/'\\'}" || return
	escaped_str="${escaped_str//'`'/'\`'}" || return
	escaped_str="${escaped_str//'$'/'\\$'}" || return
	escaped_str="${escaped_str//$'\n'/'\n'}" || return

	printf '%s' "$escaped_str"
}

#region terminal title

function __dotfiles_bash_funcs_prompt_command__is_terminal_title_supported() {
	[[ "${TERM-}" =~ ^('xterm'|'rxvt') ]]
}

function __dotfiles_bash_funcs_prompt_command__get_terminal_title() {
	#region prefix

	local term_title_prefix || return
	term_title_prefix='' || return

	if [ -n "${TERM_TITLE_PREFIX-}" ]; then
		term_title_prefix="$(__dotfiles_bash_funcs_prompt_command__escape_for_ps "$TERM_TITLE_PREFIX: ")" || return
	fi

	readonly term_title_prefix || return

	#endregion

	#region infix

	local term_title_infix || return
	term_title_infix='' || return

	if [ -n "${TERM_TITLE-}" ]; then
		# TERM_TITLE won't be escaped
		term_title_infix="$TERM_TITLE" || return
	fi

	if [ -z "$term_title_infix" ]; then
		term_title_infix='\u@\H:\w' || return
	fi

	readonly term_title_infix || return

	#endregion

	printf '%s%s' "$term_title_prefix" "$term_title_infix"
}

#endregion

#region directory contents state

function __dotfiles_bash_funcs_prompt_command__get_cwd_hidden_entry_count() {
	if ! command -v find > '/dev/null'; then
		printf 0
		return
	fi

	find . -mindepth 1 -maxdepth 1 -name '.*' -exec printf x \; | wc -c
}

function __dotfiles_bash_funcs_prompt_command__is_cwd_empty() {
	test -z "$(find . -mindepth 1 -maxdepth 1 -exec printf x \;)"
}

function __dotfiles_bash_funcs_prompt_command__is_hidden_git_dir_present() {
	local git_dir || return
	git_dir="${GIT_DIR:-".git"}" || return
	readonly git_dir || return

	[[ ! "$git_dir" =~ ^('.'|'..')$ ]] &&
		[[ "$git_dir" =~ ^'.' ]] &&
		test -e "$git_dir" &&
		{ ! command -v git > '/dev/null' || command git --no-pager status &> '/dev/null'; }
}

function __dotfiles_bash_funcs_prompt_command__get_dir_contents_state() {
	local cwd || return
	cwd="$(pwd -L && printf x)" || return
	cwd="${cwd%$'\nx'}" || return

	if [ ! -d "$cwd" ] || [ ! -x "$cwd" ] || [ ! -r "$cwd" ]; then
		return
	fi

	unset -v cwd


	local -i hidden_count || return
	hidden_count=$(__dotfiles_bash_funcs_prompt_command__get_cwd_hidden_entry_count) || return
	readonly hidden_count || return

	if ((hidden_count == 0)); then
		if __dotfiles_bash_funcs_prompt_command__is_cwd_empty; then
			printf 'nothing'
		fi

		return
	fi

	if ((hidden_count == 1)) && __dotfiles_bash_funcs_prompt_command__is_hidden_git_dir_present; then
		printf 'hidden_git_dir_only'
		return
	fi

	printf 'hidden'
}

#endregion

#region jobs

function __dotfiles_bash_funcs_prompt_command__get_job_count() {
	jobs -pr | wc -l
}

#endregion

#endregion

function __dotfiles_bash_funcs_prompt_command__update_ps_vars() {
	local -ir prev_cmd_exc=$? || return

	#region terminal effect variables

	#region literals

	local fx_reset            || return
	local fx_lit_bold         || return
	local fx_lit_gray         || return
	local fx_lit_red          || return
	local fx_lit_lightred     || return
	local fx_lit_green        || return
	local fx_lit_lightgreen   || return
	local fx_lit_yellow       || return
	local fx_lit_lightyellow  || return
	local fx_lit_blue         || return
	local fx_lit_lightblue    || return
	local fx_lit_magenta      || return
	local fx_lit_lightmagenta || return
	local fx_lit_cyan      || return
	local fx_lit_lightcyan || return

	fx_reset=''            || return
	fx_lit_bold=''         || return
	fx_lit_gray=''         || return
	fx_lit_red=''          || return
	fx_lit_lightred=''     || return
	fx_lit_green=''        || return
	fx_lit_lightgreen=''   || return
	fx_lit_yellow=''       || return
	fx_lit_lightyellow=''  || return
	fx_lit_blue=''         || return
	fx_lit_lightblue=''    || return
	fx_lit_magenta=''      || return
	fx_lit_lightmagenta='' || return
	fx_lit_cyan=''         || return
	fx_lit_lightcyan=''    || return

	if command -v is_color_supported > '/dev/null' && is_color_supported 2; then
		fx_reset="\\[$(tput sgr0)\\]"                || fx_reset=''                           || return
		fx_lit_bold="\\[$(tput bold)\\]"             || fx_lit_bold=''                        || return
		fx_lit_gray="\\[$(tput setaf 8)\\]"          || fx_lit_gray="$fx_reset"               || return
		fx_lit_red="\\[$(tput setaf 1)\\]"           || fx_lit_red="$fx_reset"                || return
		fx_lit_lightred="\\[$(tput setaf 9)\\]"      || fx_lit_lightred="$fx_lit_red"         || return
		fx_lit_green="\\[$(tput setaf 2)\\]"         || fx_lit_green="$fx_reset"              || return
		fx_lit_lightgreen="\\[$(tput setaf 10)\\]"   || fx_lit_lightgreen="$fx_lit_green"     || return
		fx_lit_yellow="\\[$(tput setaf 3)\\]"        || fx_lit_yellow="$fx_reset"             || return
		fx_lit_lightyellow="\\[$(tput setaf 11)\\]"  || fx_lit_lightyellow="$fx_lit_yellow"   || return
		fx_lit_blue="\\[$(tput setaf 4)\\]"          || fx_lit_blue="$fx_reset"               || return
		fx_lit_lightblue="\\[$(tput setaf 12)\\]"    || fx_lit_lightblue="$fx_lit_blue"       || return
		fx_lit_magenta="\\[$(tput setaf 5)\\]"       || fx_lit_magenta="$fx_reset"            || return
		fx_lit_lightmagenta="\\[$(tput setaf 13)\\]" || fx_lit_lightmagenta="$fx_lit_magenta" || return
		fx_lit_cyan="\\[$(tput setaf 6)\\]"          || fx_lit_cyan="$fx_reset"               || return
		fx_lit_lightcyan="\\[$(tput setaf 14)\\]"    || fx_lit_lightcyan="$fx_lit_cyan"       || return
	fi

	readonly fx_lit_lightcyan || return
	readonly fx_lit_cyan      || return
	readonly fx_lit_lightmagenta || return
	readonly fx_lit_magenta      || return
	readonly fx_lit_lightblue    || return
	readonly fx_lit_blue         || return
	readonly fx_lit_lightyellow  || return
	readonly fx_lit_yellow       || return
	readonly fx_lit_lightgreen   || return
	readonly fx_lit_green        || return
	readonly fx_lit_lightred     || return
	readonly fx_lit_red          || return
	readonly fx_lit_gray         || return
	readonly fx_lit_bold         || return
	readonly fx_reset            || return

	#endregion

	#region semantics

	local fx_sem_ps2                       || return
	local fx_sem_timestamp                 || return
	local fx_sem_timestamp_ps0             || return
	local fx_sem_timestamp_ps1             || return
	local fx_sem_exitcode_success          || return
	local fx_sem_exitcode_failure          || return
	local fx_sem_emptydirindicator         || return
	local fx_sem_hiddendirentriesindicator || return
	local fx_sem_hiddengitdironlyindicator || return
	local fx_sem_jobcount                  || return
	local fx_sem_shelllevel                || return
	local fx_sem_username                  || return
	local fx_sem_usernamehostnamesep       || return
	local fx_sem_hostname                  || return
	local fx_sem_dirstacksize              || return
	local fx_sem_gitrepoinfo               || return
	local fx_sem_promptchar                || return

	fx_sem_ps2="${fx_lit_lightblue}${fx_lit_bold}" || return

	fx_sem_timestamp="${fx_lit_lightgreen}" || return
	fx_sem_timestamp_ps0="$fx_sem_timestamp" || return
	fx_sem_timestamp_ps1="$fx_sem_timestamp" || return

	fx_sem_exitcode_success="${fx_lit_gray}${fx_lit_bold}"     || return
	fx_sem_exitcode_failure="${fx_lit_lightred}${fx_lit_bold}" || return

	fx_sem_emptydirindicator="${fx_lit_gray}${fx_lit_bold}"                || return
	fx_sem_hiddendirentriesindicator="${fx_lit_lightyellow}${fx_lit_bold}" || return
	fx_sem_hiddengitdironlyindicator="${fx_lit_gray}${fx_lit_bold}"        || return

	fx_sem_jobcount="${fx_lit_blue}${fx_lit_bold}" || return

	fx_sem_shelllevel="${fx_lit_gray}${fx_lit_bold}" || return

	fx_sem_username="${fx_lit_lightgreen}${fx_lit_bold}" || return

	fx_sem_usernamehostnamesep="${fx_lit_lightgreen}" || return

	fx_sem_hostname="${fx_lit_lightgreen}${fx_lit_bold}" || return

	fx_sem_dirstacksize="${fx_lit_lightmagenta}${fx_lit_bold}" || return

	fx_sem_gitrepoinfo="${fx_lit_lightcyan}${fx_lit_bold}" || return

	fx_sem_promptchar="${fx_lit_lightblue}${fx_lit_bold}" || return

	readonly fx_sem_promptchar                || return
	readonly fx_sem_gitrepoinfo               || return
	readonly fx_sem_dirstacksize              || return
	readonly fx_sem_hostname                  || return
	readonly fx_sem_usernamehostnamesep       || return
	readonly fx_sem_username                  || return
	readonly fx_sem_shelllevel                || return
	readonly fx_sem_jobcount                  || return
	readonly fx_sem_hiddengitdironlyindicator || return
	readonly fx_sem_hiddendirentriesindicator || return
	readonly fx_sem_emptydirindicator         || return
	readonly fx_sem_exitcode_failure          || return
	readonly fx_sem_exitcode_success          || return
	readonly fx_sem_timestamp_ps1             || return
	readonly fx_sem_timestamp_ps0             || return
	readonly fx_sem_timestamp                 || return
	readonly fx_sem_ps2                       || return

	#endregion

	#endregion

	#region building main prompt strings

	unset -v PS2 PS1 PS0 || return
	declare -g PS0 PS1 PS2 || return

	PS0="${fx_sem_timestamp_ps0}[\\t]${fx_reset}\\n" || return
	PS2=" ${fx_sem_ps2}>${fx_reset} " || return

	PS1='' || return

	#region terminal title

	if __dotfiles_bash_funcs_prompt_command__is_terminal_title_supported; then
		local term_title || return
		term_title="$(__dotfiles_bash_funcs_prompt_command__get_terminal_title)" || return

		# any necessary escaping is already done in __dotfiles_bash_funcs_prompt_command__get_terminal_title, so no need
		# to do it here
		PS1+="\\[\\033]0;${term_title}\\007\\]" || return

		unset -v term_title
	fi

	#endregion

	PS1+="${fx_reset}\\n" || return

	#region line 1

	#region timestamp

	local dot_with_ms || return
	dot_with_ms='' || return

	# '%N' (nanoseconds) is a GNU extensions, so we first have to check if it is supported, if not, we just omit
	# the milliseconds
	if [ "$(date +'%N')" != '%N' ]; then
		local ms || return
		ms=$((10#$(date +'%N') / 1000000)) || return

		# padding `ms` with leading zeros
		while ((${#ms} < 3)); do
			ms="0$ms" || return
		done

		dot_with_ms=".$ms" || return

		unset -v ms
	fi

	PS1+="${fx_sem_timestamp_ps1}[\\t${dot_with_ms}]${fx_reset}" || return

	unset -v dot_with_ms

	#endregion

	PS1+=' ' || return

	#region exit code of previous command

	if ((prev_cmd_exc == 0)); then
		PS1+="${fx_sem_exitcode_success}${prev_cmd_exc}${fx_reset}" || return
	else
		PS1+="${fx_sem_exitcode_failure}${prev_cmd_exc}${fx_reset}" || return
	fi

	#endregion

	#region directory contents state indicator

	local dir_contents_state || return
	dir_contents_state="$(__dotfiles_bash_funcs_prompt_command__get_dir_contents_state)" || return

	case "$dir_contents_state" in
		('nothing')
			PS1+=" ${fx_sem_emptydirindicator}(empty dir)${fx_reset}" || return
			;;
		('hidden_git_dir_only')
			PS1+=" ${fx_sem_hiddendirentriesindicator}!.*${fx_reset} ${fx_sem_hiddengitdironlyindicator}(\\\\\$GIT_DIR only)${fx_reset}" || return
			;;
		('hidden')
			PS1+=" ${fx_sem_hiddendirentriesindicator}!.*${fx_reset}" || return
			;;
	esac

	unset -v dir_contents_state

	#endregion

	#region job count

	local -i job_count || return
	job_count=$(__dotfiles_bash_funcs_prompt_command__get_job_count) || return

	if ((job_count > 0)); then
		PS1+=" ${fx_sem_jobcount}(${job_count})${fx_reset}"
	fi

	unset -v job_count

	#endregion

	#endregion

	#endregion

	PS1+='\n' || return

	#region last line

	#region shell level

	if [[ "${SHLVL-}" =~ ^[1-9][0-9]*$ ]] && ((SHLVL > 1)); then
		PS1+="${fx_sem_shelllevel}[+$((SHLVL - 1))]${fx_reset} " || return
	fi

	#endregion

	#region username & hostname

	PS1+="${fx_sem_username}\\u${fx_reset}" || return
	PS1+="${fx_sem_usernamehostnamesep}@${fx_reset}" || return
	PS1+="${fx_sem_hostname}\\H${fx_reset}" || return

	#endregion

	PS1+=':' || return

	#region directory stack size

	if ((${#DIRSTACK[@]} > 1)); then
		PS1+=" ${fx_sem_dirstacksize}+${#DIRSTACK[@]}${fx_reset}" || return
	fi

	#endregion

	PS1+=' ' || return

	#region git repository info

	if command -v git > '/dev/null' && command -v __git_ps1 > '/dev/null'; then
		local git_ps1 || return
		git_ps1="$(__git_ps1 '(%s)')" || return

		if [ -n "$git_ps1" ]; then
			PS1+="${fx_sem_gitrepoinfo}${git_ps1}${fx_reset}\\n" || return
		fi

		unset -v git_ps1
	fi

	#endregion

	#region prompt character

	PS1+="${fx_sem_promptchar}\\\$${fx_reset}" || return

	#endregion

	PS1+=' ' || return

	#endregion

	#endregion
}

#region setting the variable `PROMPT_COMMAND`

if declare -p PROMPT_COMMAND &> '/dev/null'; then
	if [[ ! "$(declare -p PROMPT_COMMAND)" =~ ^'declare -'([^'a']*'a'[^'a']*)+' ' ]]; then
		# PROMPT_COMMAND is defined, but is not an array variable

		declare __dotfiles_bash_funcs_prompt_command__tmp
		__dotfiles_bash_funcs_prompt_command__tmp="$PROMPT_COMMAND"

		unset -v PROMPT_COMMAND

		declare -a PROMPT_COMMAND
		PROMPT_COMMAND=("$__dotfiles_bash_funcs_prompt_command__tmp")

		unset -v __dotfiles_bash_funcs_prompt_command__tmp
	fi
else
	declare -a PROMPT_COMMAND
	PROMPT_COMMAND=()
fi

PROMPT_COMMAND+=(__dotfiles_bash_funcs_prompt_command__update_ps_vars)

#endregion
