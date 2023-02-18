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
	escaped_str="${escaped_str//'$'/'\$'}" || return
	escaped_str="${escaped_str//$'\n'/'\n'}" || return

	printf '%s' "$escaped_str"
}

#region directory environment variables

declare DIR_ENV_VARS_ENABLED
DIR_ENV_VARS_ENABLED='yes'

declare DIR_ENV_VARS_FILENAME
DIR_ENV_VARS_FILENAME='.direnv'

function __dotfiles_bash_funcs_prompt_command__is_dir_env_vars_enabled() {
	command -v is_truthy > '/dev/null' &&
		is_truthy "${DIR_ENV_VARS_ENABLED-}"
}

function __dotfiles_bash_funcs_prompt_command__get_dir_env_vars_filename() {
	if ! __dotfiles_bash_funcs_prompt_command__is_dir_env_vars_enabled; then
		return 48
	fi

	local filename || return
	filename="${DIR_ENV_VARS_FILENAME-}" || return
	readonly filename || return

	if [ -z "$filename" ] || [[ "$filename" =~ ('/'|^('.'|'..')$) ]]; then
		return 49
	fi

	printf '%s' "$filename"
}

function __dotfiles_bash_funcs_prompt_command__is_dir_env_vars_file_ok() {
	if ! __dotfiles_bash_funcs_prompt_command__is_dir_env_vars_enabled; then
		return 32
	fi

	local dir_env_vars_filename || return
	dir_env_vars_filename="$(__dotfiles_bash_funcs_prompt_command__get_dir_env_vars_filename && printf x)" || return
	dir_env_vars_filename="${dir_env_vars_filename%x}" || return
	readonly dir_env_vars_filename || return

	test -e "$dir_env_vars_filename" &&
		test -f "$dir_env_vars_filename" &&
		test -r "$dir_env_vars_filename"
}

declare -A __dotfiles_bash_funcs_prompt_command__dir_env_var_map
__dotfiles_bash_funcs_prompt_command__dir_env_var_map=()

function __dotfiles_bash_funcs_prompt_command__unset_dir_env_vars_and_clear_dir_env_var_map() {
	local var_name || return

	for var_name in "${!__dotfiles_bash_funcs_prompt_command__dir_env_var_map[@]}"; do
		local cached_var_value || return
		cached_var_value="${__dotfiles_bash_funcs_prompt_command__dir_env_var_map["$var_name"]}" || return

		if [ "${!var_name+"is_set"}" = 'is_set' ]; then
			local real_var_value="${!var_name}" || return

			if [ "$real_var_value" = "$cached_var_value" ]; then
				unset -v "$var_name" || return
			fi

			unset -v real_var_value
		fi

		unset -v cached_var_value
	done

	__dotfiles_bash_funcs_prompt_command__dir_env_var_map=()
}

function __dotfiles_bash_funcs_prompt_command__update_dir_env_var_map() {
	__dotfiles_bash_funcs_prompt_command__unset_dir_env_vars_and_clear_dir_env_var_map || return

	if ! __dotfiles_bash_funcs_prompt_command__is_dir_env_vars_file_ok; then
		return
	fi

	local dir_env_vars_filename || return
	dir_env_vars_filename="$(__dotfiles_bash_funcs_prompt_command__get_dir_env_vars_filename && printf x)" || return
	dir_env_vars_filename="${dir_env_vars_filename%x}" || return
	readonly dir_env_vars_filename || return

	local line || return
	while read -r line; do
		if [[ ! "$line" =~ ^([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
			continue
		fi

		local var_name="${BASH_REMATCH[1]}" || return

		if [ "${!var_name+"is_set"}" != 'is_set' ]; then
			local var_value="${BASH_REMATCH[2]}" || return

			__dotfiles_bash_funcs_prompt_command__dir_env_var_map+=(["$var_name"]="$var_value") || return
			export "$var_name"="$var_value" || return

			unset -v var_value
		fi

		unset -v var_name
	done < "$dir_env_vars_filename"
}

#endregion

#region preview mode

declare PREVIEW_MODE_ENABLED
PREVIEW_MODE_ENABLED='no'

function __dotfiles_bash_funcs_prompt_command__is_preview_mode_enabled() {
	command -v is_truthy > '/dev/null' &&
		is_truthy "${PREVIEW_MODE_ENABLED-}"
}

#endregion

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

function __dotfiles_bash_funcs_prompt_command__is_hidden_dir_env_vars_file_ok() {
	local dir_env_vars_filename || return
	dir_env_vars_filename="$(__dotfiles_bash_funcs_prompt_command__get_dir_env_vars_filename && printf x)" || return
	dir_env_vars_filename="${dir_env_vars_filename%x}" || return
	readonly dir_env_vars_filename || return

	[[ "$dir_env_vars_filename" =~ ^'.' ]] &&
		__dotfiles_bash_funcs_prompt_command__is_dir_env_vars_file_ok
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

	if ((hidden_count == 1)); then
		if __dotfiles_bash_funcs_prompt_command__is_hidden_git_dir_present; then
			printf 'hidden_git_dir_only'
			return
		fi

		if __dotfiles_bash_funcs_prompt_command__is_hidden_dir_env_vars_file_ok; then
			printf 'hidden_dir_env_vars_file_only'
			return
		fi
	fi

	if __dotfiles_bash_funcs_prompt_command__is_hidden_dir_env_vars_file_ok; then
		printf 'hidden_with_hidden_dir_env_vars_file'
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

#region low storage space warning

#region math engine

# TODO: add support for `dc` (?) (not defined by POSIX btw)
# TODO: add support for `node`

#region checking bash long arithmetic support

declare __dotfiles_bash_funcs_prompt_command__math_engine__bash_long_arithmetic_supported
__dotfiles_bash_funcs_prompt_command__math_engine__bash_long_arithmetic_supported=false

if [ $((9223372036854775807)) = 9223372036854775807 ] && [ $((-9223372036854775808)) = '-9223372036854775808' ]; then
	__dotfiles_bash_funcs_prompt_command__math_engine__bash_long_arithmetic_supported=true
fi

#endregion

#region engine names

function __dotfiles_bash_funcs_prompt_command__math_engine__get_available_integer_engine_names() {
	local out || return
	out='' || return

	if command -v bc > '/dev/null'; then
		out+='[bc]' || return
	fi

	# TODO: dc

	if command -v python3 > '/dev/null'; then
		out+='[python3]' || return
	fi

	if command -v python > '/dev/null'; then
		out+='[python]' || return
	fi

	if command -v python2 > '/dev/null'; then
		out+='[python2]' || return
	fi

	if $__dotfiles_bash_funcs_prompt_command__math_engine__bash_long_arithmetic_supported; then
		out+='[bash]' || return
	fi

	if command -v awk > '/dev/null'; then
		out+='[awk]' || return
	fi

	# TODO: node

	if [[ "$out" != *'[bash]'* ]]; then
		out+='[bash]' || return
	fi

	readonly out || return

	printf '%s' "$out"
}

function __dotfiles_bash_funcs_prompt_command__math_engine__get_available_decimal_engine_names() {
	local out || return
	out='' || return

	if command -v bc > '/dev/null'; then
		out+='[bc]' || return
	fi

	# TODO: dc

	if command -v python3 > '/dev/null'; then
		out+='[python3]' || return
	fi

	if command -v python > '/dev/null'; then
		out+='[python]' || return
	fi

	if command -v python2 > '/dev/null'; then
		out+='[python2]' || return
	fi

	# TODO: node

	if command -v awk > '/dev/null'; then
		out+='[awk]' || return
	fi

	if [ -z "$out" ]; then
		out+='[bash]' || return
	fi

	readonly out || return

	printf '%s' "$out"
}

#endregion

#region operations

function __dotfiles_bash_funcs_prompt_command__math_engine__integer_multiply() {
	local multiplier multiplicand || return

	multiplier="$1" || return
	multiplicand="$2" || return

	readonly multiplicand multiplier || return

	local engine_names || return
	engine_names="$(__dotfiles_bash_funcs_prompt_command__math_engine__get_available_integer_engine_names)" || return
	readonly engine_names || return

	case "$engine_names" in
		(*'[bc]'*)
			# newline is needed here
			printf '(%s) * (%s)\n' "$multiplier" "$multiplicand" | bc
			return
			;;
		(*'[python3]'*)
			python3 -c "print(int($multiplier) * int($multiplicand))"
			return
			;;
		(*'[python]'*)
			python  -c "print(int($multiplier) * int($multiplicand))"
			return
			;;
		('[python2]'*)
			python2 -c "print(int($multiplier) * int($multiplicand))"
			return
			;;
		(*'[bash]'*)
			printf '%s' $((multiplier * multiplicand))
			return
			;;
		(*'[awk]'*)
			awk "BEGIN { print(($multiplier) * ($multiplicand)); }"
			return
			;;
		(*)
			printf '%s: no suitable integer math engine is available\n' "${FUNCNAME[0]}" >&2
			return 48
			;;
	esac
}

function __dotfiles_bash_funcs_prompt_command__math_engine__decimal_multiply() {
	local multiplier multiplicand || return

	multiplier="$1" || return
	multiplicand="$2" || return

	readonly multiplicand multiplier || return

	local engine_names || return
	engine_names="$(__dotfiles_bash_funcs_prompt_command__math_engine__get_available_decimal_engine_names)" || return
	readonly engine_names || return

	case "$engine_names" in
		(*'[bc]'*)
			local product || return
			# newline is needed here
			product="$(printf '(%s) * (%s)\n' "$multiplier" "$multiplicand" | bc -l)" || return

			if [[ "$product" =~ ^'.' ]]; then
				product="0$product" || return
			fi

			readonly product || return

			printf '%s' "$product"
			return
			;;
		(*'[python3]'*)
			python3 -c "print(float($multiplier) * float($multiplicand))"
			return
			;;
		(*'[python]'*)
			python  -c "print(float($multiplier) * float($multiplicand))"
			return
			;;
		(*'[python2]'*)
			python2 -c "print(float($multiplier) * float($multiplicand))"
			return
			;;
		(*'[awk]'*)
			awk "BEGIN { print(($multiplier) * ($multiplicand)); }"
			return
			;;
		(*'[bash]'*)
			local multiplier_int multiplicand_int || return

			multiplier_int="$(__dotfiles_bash_funcs_prompt_command__math_engine__round_to_integer "$multiplier")" || return
			multiplicand_int="$(__dotfiles_bash_funcs_prompt_command__math_engine__round_to_integer "$multiplicand")" || return

			readonly multiplicand_int multiplier_int || return

			printf '%s' $((multiplicand_int * multiplier_int))
			return
			;;
		(*)
			printf '%s: no suitable decimal math engine is available\n' "${FUNCNAME[0]}" >&2
			return 48
			;;
	esac
}

function __dotfiles_bash_funcs_prompt_command__math_engine__decimal_divide() {
	local dividend divisor || return

	dividend="$1" || return
	divisor="$2" || return

	readonly divisor dividend || return

	local engine_names || return
	engine_names="$(__dotfiles_bash_funcs_prompt_command__math_engine__get_available_decimal_engine_names)" || return
	readonly engine_names || return

	case "$engine_names" in
		(*'[bc]'*)
			local quotient || return
			# newline is needed here
			quotient="$(printf '(%s) / (%s)\n' "$dividend" "$divisor" | bc -l)" || return

			if [[ "$quotient" =~ ^'.' ]]; then
				quotient="0$quotient" || return
			fi

			readonly quotient || return

			printf '%s' "$quotient"
			return
			;;
		(*'[python3]'*)
			python3 -c "print(float($dividend) / float($divisor))"
			return
			;;
		(*'[python]'*)
			python  -c "print(float($dividend) / float($divisor))"
			return
			;;
		(*'[python2]'*)
			python2 -c "print(float($dividend) / float($divisor))"
			return
			;;
		(*'[awk]'*)
			awk "BEGIN { print(($multiplier) / ($multiplicand)); }"
			return
			;;
		(*'[bash]'*)
			local multiplier_int multiplicand_int || return

			multiplier_int="$(__dotfiles_bash_funcs_prompt_command__math_engine__round_to_integer "$multiplier")" || return
			multiplicand_int="$(__dotfiles_bash_funcs_prompt_command__math_engine__round_to_integer "$multiplicand")" || return

			readonly multiplicand_int multiplier_int || return

			printf '%s' $((multiplicand_int / multiplier_int))
			return
			;;
		(*)
			printf '%s: no suitable decimal math engine is available\n' "${FUNCNAME[0]}" >&2
			return 48
			;;
	esac
}

function __dotfiles_bash_funcs_prompt_command__math_engine__integer_equals() {
	local num1 num2 || return

	num1="$1" || return
	num2="$2" || return

	readonly num2 num1 || return

	local engine_names || return
	engine_names="$(__dotfiles_bash_funcs_prompt_command__math_engine__get_available_integer_engine_names)" || return
	readonly engine_names || return

	case "$engine_names" in
		(*'[bc]'*)
			local result || return

			# newline is needed here
			result="$(printf '(%s) == (%s)\n' "$num1" "$num2" | bc)" || return

			readonly result || return

			if [ "$result" = '1' ]; then
				return 0
			else
				return 32
			fi
			;;
		(*'[python3]'*)
			python3 -c "exit(0 if int($num1) == int($num2) else 32)"
			return
			;;
		(*'[python]'*)
			python  -c "exit(0 if int($num1) == int($num2) else 32)"
			return
			;;
		(*'[python2]'*)
			python2 -c "exit(0 if int($num1) == int($num2) else 32)"
			return
			;;
		(*'[bash]'*)
			if ((num1 == num2)); then
				return 0
			else
				return 32
			fi
			;;
		(*'[awk]'*)
			awk "BEGIN { exit((int($num1) == int($num2)) ? 0 : 32); }"
			return
			;;
		(*)
			printf '%s: no suitable integer math engine is available\n' "${FUNCNAME[0]}" >&2
			return 48
			;;
	esac
}

function __dotfiles_bash_funcs_prompt_command__math_engine__decimal_greater_than() {
	local num1 num2 || return

	num1="$1" || return
	num2="$2" || return

	readonly num2 num1 || return

	local engine_names || return
	engine_names="$(__dotfiles_bash_funcs_prompt_command__math_engine__get_available_decimal_engine_names)" || return
	readonly engine_names || return

	case "$engine_names" in
		(*'[bc]'*)
			local result || return

			# newline is needed here
			result="$(printf '%s > %s\n' "$num1" "$num2" | bc)" || return

			readonly result || return

			if [ "$result" = '1' ]; then
				return 0
			else
				return 32
			fi
			;;
		(*'[python3]'*)
			python3 -c "exit(0 if float($num1) > float($num2) else 32)"
			return
			;;
		(*'[python]'*)
			python  -c "exit(0 if float($num1) > float($num2) else 32)"
			return
			;;
		(*'[python2]'*)
			python2 -c "exit(0 if float($num1) > float($num2) else 32)"
			return
			;;
		(*'[awk]'*)
			awk "BEGIN { exit(($num1 > $num2) ? 0 : 32); }"
			return
			;;
		(*'[bash]'*)
			local num1_int num2_int || return

			num1_int=$(__dotfiles_bash_funcs_prompt_command__math_engine__round_to_integer "$num1") || return
			num2_int=$(__dotfiles_bash_funcs_prompt_command__math_engine__round_to_integer "$num2") || return

			readonly num2_int num1_int || return

			if ((num1_int > num2_int)); then
				return 0
			else
				return 32
			fi
			;;
		(*)
			printf '%s: no suitable decimal math engine is available\n' "${FUNCNAME[0]}" >&2
			return 48
			;;
	esac
}

function __dotfiles_bash_funcs_prompt_command__math_engine__decimal_equal_or_greater_than() {
	local num1 num2 || return

	num1="$1" || return
	num2="$2" || return

	readonly num2 num1 || return

	local engine_names || return
	engine_names="$(__dotfiles_bash_funcs_prompt_command__math_engine__get_available_decimal_engine_names)" || return
	readonly engine_names || return

	case "$engine_names" in
		(*'[bc]'*)
			local result || return

			# newline is needed here
			result="$(printf '%s >= %s\n' "$num1" "$num2" | bc)" || return

			readonly result || return

			if [ "$result" = '1' ]; then
				return 0
			else
				return 32
			fi
			;;
		(*'[python3]'*)
			python3 -c "exit(0 if float($num1) >= float($num2) else 32)"
			return
			;;
		(*'[python]'*)
			python  -c "exit(0 if float($num1) >= float($num2) else 32)"
			return
			;;
		(*'[python2]'*)
			python2 -c "exit(0 if float($num1) >= float($num2) else 32)"
			return
			;;
		(*'[awk]'*)
			awk "BEGIN { exit(($num1 >= $num2) ? 0 : 32); }"
			return
			;;
		(*'[bash]'*)
			local num1_int num2_int || return

			num1_int=$(__dotfiles_bash_funcs_prompt_command__math_engine__round_to_integer "$num1") || return
			num2_int=$(__dotfiles_bash_funcs_prompt_command__math_engine__round_to_integer "$num2") || return

			readonly num2_int num1_int || return

			if ((num1_int >= num2_int)); then
				return 0
			else
				return 32
			fi
			;;
		(*)
			printf '%s: no suitable decimal math engine is available\n' "${FUNCNAME[0]}" >&2
			return 48
			;;
	esac
}

#endregion

#region round

function __dotfiles_bash_funcs_prompt_command__math_engine__round() {
	local num scale || return

	num="$1" || return
	scale="$2" || return

	readonly scale num || return

	local engine_names || return
	engine_names="$(__dotfiles_bash_funcs_prompt_command__math_engine__get_available_decimal_engine_names)" || return
	readonly engine_names || return

	case "$engine_names" in
		(*'[python3]'*)
			python3 -c "print(round(float($num), int($scale)))"
			return
			;;
		(*'[python]'*)
			python  -c "print(round(float($num), int($scale)))"
			return
			;;
		(*'[python2]'*)
			python2 -c "print(round(float($num), int($scale)))"
			return
			;;
		# TODO: other engines
		(*)
			printf '%s: no suitable decimal math engine is available\n' "${FUNCNAME[0]}" >&2
			return 48
			;;
	esac
}

function __dotfiles_bash_funcs_prompt_command__math_engine__round_to_integer() {
	local num || return
	num="$1" || return
	readonly num || return

	local engine_names || return
	engine_names="$(__dotfiles_bash_funcs_prompt_command__math_engine__get_available_decimal_engine_names)" || return
	readonly engine_names || return

	case "$engine_names" in
		(*'[python3]'*)
			python3 -c "print(int(round(float($num))))"
			return
			;;
		(*'[python]'*)
			python  -c "print(int(round(float($num))))"
			return
			;;
		(*'[python2]'*)
			python2 -c "print(int(round(float($num))))"
			return
			;;
		(*'[awk]'*)
			awk "BEGIN { print(int($num)); }"
			;;
		# TODO: other engines
		(*)
			printf '%s: no suitable decimal math engine is available\n' "${FUNCNAME[0]}" >&2
			return 48
			;;
	esac
}

#endregion

#endregion

function __dotfiles_bash_funcs_prompt_command__space_human_readable() {
	local bytes || return
	bytes="$1" || return
	readonly bytes || return

	local -a units || return
	units=(
		'B'
		'KiB'
		'MiB'
		'GiB'
		'TiB'
		'PiB'
		'EiB'
		'ZiB'
		'YiB'
	) || return
	readonly units || return

	local value || return
	value="$bytes" || return

	local -i unit_index || return
	unit_index=0 || return

	while (((unit_index + 1) < ${#units[@]})) &&
	      __dotfiles_bash_funcs_prompt_command__math_engine__decimal_equal_or_greater_than "$value" 1024; do

		value="$(__dotfiles_bash_funcs_prompt_command__math_engine__decimal_divide "$value" 1024)" || return
		((++unit_index)) || return
	done

	value="$(__dotfiles_bash_funcs_prompt_command__math_engine__round_to_integer "$value")" || return

	readonly unit_index value || return

	printf '%s%s' "$value" "${units[unit_index]}"
}

function __dotfiles_bash_funcs_prompt_command__build_low_storage_space_warning_string() {
	local total_bytes used_bytes avail_bytes || return

	local df_line || return
	df_line="$(POSIXLY_CORRECT=yes POSIX_ME_HARDER=yes command df -kP '.' | tail -n1)" || return

	if [[ ! "$df_line" =~ [[:space:]]+(0|[1-9][0-9]*)[[:space:]]+(0|[1-9][0-9]*)[[:space:]]+((0|[1-9][0-9]*))[[:space:]]+((0|[1-9][0-9]*)%|-) ]]; then
		return
	fi

	total_bytes="$(__dotfiles_bash_funcs_prompt_command__math_engine__integer_multiply "${BASH_REMATCH[1]}" 1024)" || return
	used_bytes="$(__dotfiles_bash_funcs_prompt_command__math_engine__integer_multiply  "${BASH_REMATCH[2]}" 1024)" || return
	avail_bytes="$(__dotfiles_bash_funcs_prompt_command__math_engine__integer_multiply "${BASH_REMATCH[3]}" 1024)" || return

	unset -v df_line

	readonly avail_bytes used_bytes total_bytes || return


	# on virtual filesystems (e.g.: '/proc') the total size will be 0, which means we can ignore it
	if __dotfiles_bash_funcs_prompt_command__math_engine__integer_equals "$total_bytes" 0; then
		return
	fi


	local usage_ratio || return
	usage_ratio="$(__dotfiles_bash_funcs_prompt_command__math_engine__decimal_divide "$used_bytes" "$total_bytes")" || return
	readonly usage_ratio || return

	if ! __dotfiles_bash_funcs_prompt_command__math_engine__decimal_greater_than "$usage_ratio" 0.95; then
		return
	fi


	local avail_human_readable || return
	avail_human_readable="$(__dotfiles_bash_funcs_prompt_command__space_human_readable "$avail_bytes")" || return
	readonly avail_human_readable || return

	local total_human_readable || return
	total_human_readable="$(__dotfiles_bash_funcs_prompt_command__space_human_readable "$total_bytes")" || return
	readonly total_human_readable || return

	local usage_percent || return
	usage_percent="$(__dotfiles_bash_funcs_prompt_command__math_engine__decimal_multiply "$usage_ratio" 100)" || return
	usage_percent="$(__dotfiles_bash_funcs_prompt_command__math_engine__round "$usage_percent" 2)" || return
	readonly usage_percent || return

	printf '!!! Available %s of %s (%s%%) !!!' "$avail_human_readable" "$total_human_readable" "$usage_percent"
}

#endregion

#region directory information

declare DIR_INFO_ENABLED
DIR_INFO_ENABLED='yes'

declare DIR_INFO_FILENAME
DIR_INFO_FILENAME='.dirinfo'

declare DIR_INFO_LINE_PREFIX
DIR_INFO_LINE_PREFIX='(i) '

function __dotfiles_bash_funcs_prompt_command__get_dir_info() {
	if ! command -v is_truthy > '/dev/null' || ! is_truthy "${DIR_INFO_ENABLED-}"; then
		return
	fi

	local filename || return
	filename="${DIR_INFO_FILENAME-}" || return
	readonly filename || return

	if [ -z "$filename" ] || [[ "$filename" =~ ('/'|^('.'|'..')$) ]] ||
	   [ ! -e "$filename" ] || [ ! -f "$filename" ] || [ ! -r "$filename" ]; then

		return
	fi

	local line_prefix || return
	line_prefix="${DIR_INFO_LINE_PREFIX-}" || return
	readonly line_prefix || return

	local dirinfo || return
	dirinfo='' || return

	local line || return

	# readling line-by-line to automatically trim whitespace
	while read -rs line; do
		if [ -z "$line" ]; then
			continue
		fi

		if [ -n "$dirinfo" ]; then
			dirinfo+=$'\n' || return
		fi

		dirinfo+="${line_prefix}${line}" || return
	done < "$filename"

	unset -v line

	readonly dirinfo || return

	printf '%s' "$dirinfo"
}

#endregion

#region current working directory

function __dotfiles_bash_funcs_prompt_command__get_cwd_state() {
	# using '.' here wouldn't work, because when querying '.', it is reported to always exist and be a directory, even
	# if that is not the real case

	local absolute_cwd_pathname || return
	absolute_cwd_pathname="$(pwd -L && printf x)" || return
	absolute_cwd_pathname="${absolute_cwd_pathname%$'\nx'}" || return
	readonly absolute_cwd_pathname || return

	if [ ! -e "$absolute_cwd_pathname" ]; then
		printf 'missing'
		return
	fi

	if [ ! -d "$absolute_cwd_pathname" ]; then
		printf 'not_dir'
		return
	fi

	printf 'ok'
}

#endregion

function __dotfiles_bash_funcs_prompt_command__is_effective_user_root() {
	local uid || return
	uid="$(id -u)" || return
	readonly uid || return

	test "$uid" = '0'
}

#endregion

function __dotfiles_bash_funcs_prompt_command__update_ps_vars() {
	local -ir prev_cmd_exc=$? || return

	__dotfiles_bash_funcs_prompt_command__update_dir_env_var_map || return

	#region preview mode

	if __dotfiles_bash_funcs_prompt_command__is_preview_mode_enabled; then
		unset -v PS2 PS1 PS0 || return
		declare -g PS0 PS1 PS2 || return

		PS0=''    || return
		PS1='\$ ' || return
		PS2='> '  || return

		return
	fi

	#endregion

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

	local fx_sem_ps2                               || return
	local fx_sem_timestamp                         || return
	local fx_sem_timestamp_ps0                     || return
	local fx_sem_timestamp_ps1                     || return
	local fx_sem_exitcode_success                  || return
	local fx_sem_exitcode_failure                  || return
	local fx_sem_emptydirindicator                 || return
	local fx_sem_hiddendirentriesindicator         || return
	local fx_sem_hiddengitdironlyindicator         || return
	local fx_sem_hiddendirenvvarsfileindicator     || return
	local fx_sem_hiddendirenvvarsfileonlyindicator || return
	local fx_sem_jobcount                          || return
	local fx_sem_lowstoragespacewarning            || return
	local fx_sem_dirinfo                           || return
	local fx_sem_shelllevel                        || return
	local fx_sem_username                          || return
	local fx_sem_username_nonroot                  || return
	local fx_sem_username_root                     || return
	local fx_sem_usernamehostnamesep               || return
	local fx_sem_hostname                          || return
	local fx_sem_cwd                               || return
	local fx_sem_cwd_valid                         || return
	local fx_sem_cwd_invalid                       || return
	local fx_sem_cwd_invalid_missing               || return
	local fx_sem_cwd_invalid_notdir                || return
	local fx_sem_dirstacksize                      || return
	local fx_sem_gitrepoinfo                       || return
	local fx_sem_promptchar                        || return
	local fx_sem_promptchar_nonroot                || return
	local fx_sem_promptchar_root                   || return

	fx_sem_ps2="${fx_lit_lightblue}${fx_lit_bold}" || return

	fx_sem_timestamp="${fx_lit_lightgreen}" || return
	fx_sem_timestamp_ps0="$fx_sem_timestamp" || return
	fx_sem_timestamp_ps1="$fx_sem_timestamp" || return

	fx_sem_exitcode_success="${fx_lit_gray}${fx_lit_bold}"     || return
	fx_sem_exitcode_failure="${fx_lit_lightred}${fx_lit_bold}" || return

	fx_sem_emptydirindicator="${fx_lit_gray}${fx_lit_bold}"                          || return
	fx_sem_hiddendirentriesindicator="${fx_lit_lightyellow}${fx_lit_bold}"           || return
	fx_sem_hiddengitdironlyindicator="${fx_lit_gray}${fx_lit_bold}"                  || return
	fx_sem_hiddendirenvvarsfileindicator="${fx_lit_gray}${fx_lit_bold}"              || return
	fx_sem_hiddendirenvvarsfileonlyindicator="$fx_sem_hiddendirenvvarsfileindicator" || return

	fx_sem_jobcount="${fx_lit_blue}${fx_lit_bold}" || return

	fx_sem_lowstoragespacewarning="${fx_lit_lightred}${fx_lit_bold}" || return

	fx_sem_dirinfo="${fx_lit_lightyellow}" || return

	fx_sem_shelllevel="${fx_lit_gray}${fx_lit_bold}" || return

	fx_sem_username="${fx_lit_lightgreen}${fx_lit_bold}"    || return
	fx_sem_username_nonroot="$fx_sem_username"              || return
	fx_sem_username_root="${fx_lit_lightred}${fx_lit_bold}" || return

	fx_sem_usernamehostnamesep="${fx_lit_lightgreen}" || return

	fx_sem_hostname="${fx_lit_lightgreen}${fx_lit_bold}" || return

	fx_sem_cwd="${fx_lit_lightblue}${fx_lit_bold}"             || return
	fx_sem_cwd_valid="$fx_sem_cwd"                             || return
	fx_sem_cwd_invalid="${fx_lit_lightred}${fx_lit_bold}"      || return
	fx_sem_cwd_invalid_missing="$fx_sem_cwd_invalid"           || return
	fx_sem_cwd_invalid_notdir="${fx_lit_yellow}${fx_lit_bold}" || return

	fx_sem_dirstacksize="${fx_lit_lightmagenta}${fx_lit_bold}" || return

	fx_sem_gitrepoinfo="${fx_lit_lightcyan}${fx_lit_bold}" || return

	fx_sem_promptchar="${fx_lit_lightblue}${fx_lit_bold}"     || return
	fx_sem_promptchar_nonroot="$fx_sem_promptchar"            || return
	fx_sem_promptchar_root="${fx_lit_lightred}${fx_lit_bold}" || return

	readonly fx_sem_promptchar_root                   || return
	readonly fx_sem_promptchar_nonroot                || return
	readonly fx_sem_promptchar                        || return
	readonly fx_sem_gitrepoinfo                       || return
	readonly fx_sem_dirstacksize                      || return
	readonly fx_sem_cwd_invalid_notdir                || return
	readonly fx_sem_cwd_invalid_missing               || return
	readonly fx_sem_cwd_invalid                       || return
	readonly fx_sem_cwd_valid                         || return
	readonly fx_sem_cwd                               || return
	readonly fx_sem_hostname                          || return
	readonly fx_sem_usernamehostnamesep               || return
	readonly fx_sem_username_root                     || return
	readonly fx_sem_username_nonroot                  || return
	readonly fx_sem_username                          || return
	readonly fx_sem_shelllevel                        || return
	readonly fx_sem_dirinfo                           || return
	readonly fx_sem_lowstoragespacewarning            || return
	readonly fx_sem_jobcount                          || return
	readonly fx_sem_hiddendirenvvarsfileonlyindicator || return
	readonly fx_sem_hiddendirenvvarsfileindicator     || return
	readonly fx_sem_hiddengitdironlyindicator         || return
	readonly fx_sem_hiddendirentriesindicator         || return
	readonly fx_sem_emptydirindicator                 || return
	readonly fx_sem_exitcode_failure                  || return
	readonly fx_sem_exitcode_success                  || return
	readonly fx_sem_timestamp_ps1                     || return
	readonly fx_sem_timestamp_ps0                     || return
	readonly fx_sem_timestamp                         || return
	readonly fx_sem_ps2                               || return

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
			PS1+=" ${fx_sem_hiddendirentriesindicator}!.*${fx_reset} ${fx_sem_hiddengitdironlyindicator}(\\\$GIT_DIR only)${fx_reset}" || return
			;;
		('hidden_dir_env_vars_file_only')
			local dir_env_vars_filename || return
			dir_env_vars_filename="$(__dotfiles_bash_funcs_prompt_command__get_dir_env_vars_filename && printf x)" || return
			dir_env_vars_filename="${dir_env_vars_filename%x}" || return
			dir_env_vars_filename="$(__dotfiles_bash_funcs_prompt_command__escape_for_ps "$dir_env_vars_filename")" || return

			# shellcheck disable=1003
			PS1+=" ${fx_sem_hiddendirentriesindicator}!.*${fx_reset} ${fx_sem_hiddendirenvvarsfileindicator}($dir_env_vars_filename only)${fx_reset}" || return

			unset -v dir_env_vars_filename
			;;
		('hidden_with_hidden_dir_env_vars_file')
			local dir_env_vars_filename || return
			dir_env_vars_filename="$(__dotfiles_bash_funcs_prompt_command__get_dir_env_vars_filename && printf x)" || return
			dir_env_vars_filename="${dir_env_vars_filename%x}" || return
			dir_env_vars_filename="$(__dotfiles_bash_funcs_prompt_command__escape_for_ps "$dir_env_vars_filename")" || return

			# shellcheck disable=1003
			PS1+=" ${fx_sem_hiddendirentriesindicator}!.*${fx_reset} ${fx_sem_hiddendirenvvarsfileonlyindicator}($dir_env_vars_filename)${fx_reset}" || return

			unset -v dir_env_vars_filename
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

	#region low storage space warning

	local low_storage_space_warning_str || return
	low_storage_space_warning_str="$(__dotfiles_bash_funcs_prompt_command__build_low_storage_space_warning_string)" || return

	if [ -n "$low_storage_space_warning_str" ]; then
		low_storage_space_warning_str="$(__dotfiles_bash_funcs_prompt_command__escape_for_ps "$low_storage_space_warning_str")" || return

		PS1+="\\n${fx_sem_lowstoragespacewarning}${low_storage_space_warning_str}${fx_reset}" || return
	fi

	unset -v low_storage_space_warning_str

	#endregion

	PS1+='\n' || return

	#region directory information

	local dir_info || return
	dir_info="$(__dotfiles_bash_funcs_prompt_command__get_dir_info)" || return

	if [ -n "$dir_info" ]; then
		dir_info=" ${dir_info//$'\n'/$'\n '}" || return
		dir_info="$(__dotfiles_bash_funcs_prompt_command__escape_for_ps "$dir_info")" || return

		PS1+="${fx_sem_dirinfo}${dir_info}${fx_reset}\\n" || return
	fi

	unset -v dir_info

	#endregion

	#region last line

	#region shell level

	if [[ "${SHLVL-}" =~ ^[1-9][0-9]*$ ]] && ((SHLVL > 1)); then
		PS1+="${fx_sem_shelllevel}[+$((SHLVL - 1))]${fx_reset} " || return
	fi

	#endregion

	#region username & hostname

	if ! __dotfiles_bash_funcs_prompt_command__is_effective_user_root; then
		PS1+="${fx_sem_username_nonroot}\\u${fx_reset}" || return
	else
		PS1+="${fx_sem_username_root}\\u${fx_reset}" || return
	fi

	PS1+="${fx_sem_usernamehostnamesep}@${fx_reset}" || return

	PS1+="${fx_sem_hostname}\\H${fx_reset}" || return

	#endregion

	PS1+=':' || return

	#region current working directory

	local cwd_state || return
	cwd_state="$(__dotfiles_bash_funcs_prompt_command__get_cwd_state)" || return

	case "$cwd_state" in
		('ok')
			PS1+="${fx_sem_cwd_valid}\\w${fx_reset}" || return
			;;
		('missing')
			PS1+="${fx_sem_cwd_invalid_missing}\\w${fx_reset}" || return
			;;
		('not_dir')
			PS1+="${fx_sem_cwd_invalid_notdir}\\w${fx_reset}" || return
			;;
	esac

	unset -v cwd_state

	#endregion

	#region directory stack size

	if ((${#DIRSTACK[@]} > 1)); then
		PS1+=" ${fx_sem_dirstacksize}+${#DIRSTACK[@]}${fx_reset}" || return
	fi

	#endregion

	#region git repository info

	if command -v git > '/dev/null' && command -v __git_ps1 > '/dev/null'; then
		local git_ps1 || return
		git_ps1="$(__git_ps1 '(%s)')" || return

		if [ -n "$git_ps1" ]; then
			PS1+=" ${fx_sem_gitrepoinfo}${git_ps1}${fx_reset}\\n" || return
		else
			PS1+=' ' || return
		fi

		unset -v git_ps1
	fi

	#endregion

	#region prompt character

	if ! __dotfiles_bash_funcs_prompt_command__is_effective_user_root; then
		PS1+="${fx_sem_promptchar_nonroot}\\\$${fx_reset}" || return
	else
		PS1+="${fx_sem_promptchar_root}\\\$${fx_reset}" || return
	fi

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

function toggle-preview-mode() {
	if (($# > 0)); then
		printf '%s: too many arguments: %i\n' "${FUNCNAME[0]}" $# >&2
		return 4
	fi

	if __dotfiles_bash_funcs_prompt_command__is_preview_mode_enabled; then
		PREVIEW_MODE_ENABLED='no'
	else
		PREVIEW_MODE_ENABLED='yes'
	fi
}
