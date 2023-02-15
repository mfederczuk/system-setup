# Copyright (c) 2023 Michael Federczuk
# SPDX-License-Identifier: MPL-2.0 AND Apache-2.0

#region checking for required programs

declare __dotfiles_bash_funcs_yeet__cmd

for __dotfiles_bash_funcs_yeet__cmd in try_as_root umount udisksctl; do
	if ! command -v "$__dotfiles_bash_funcs_yeet__cmd" > '/dev/null'; then
		return
	fi
done

unset -v __dotfiles_bash_funcs_yeet__cmd

#endregion

function yeet() {
	#region checking for required programs

	declare cmd

	for cmd in try_as_root umount udisksctl; do
		if ! command -v "$cmd" > '/dev/null'; then
			printf '%s: %s: program missing\n' "${FUNCNAME[0]}" "$cmd" >&2
			return 27
		fi
	done

	unset -v cmd

	#endregion

	if (($# == 0)); then
		{
			printf '%s: missing arguments: <devices>...\n' "${FUNCNAME[0]}"
			printf 'usage: %s <devices>...\n' "${FUNCNAME[0]}"
		} >&2
		return 3
	fi

	#region args

	local -a device_pathnames || return
	device_pathnames=() || return

	local -a args || return
	args=("$@") || return

	local -i i || return
	for ((i = 0; i < ${#args[@]}; ++i)); do
		local arg || return
		arg="${args[i]}" || return

		if [ -z "$arg" ]; then
			if ((${#args[@]} == 1)); then
				printf '%s: argument must not be empty\n' "${FUNCNAME[0]}" >&2
				return 9
			fi

			printf '%s: argument %i: must not be empty\n' "${FUNCNAME[0]}" $((i + 1)) >&2
			return 9
		fi

		if ((${#arg} == 1)); then
			arg="sd$arg" || return
		fi

		if [[ "$arg" =~ ^'sd'.+ ]]; then
			arg="/dev/$arg" || return
		fi

		device_pathnames+=("$arg")

		unset -v arg || return
	done
	unset -v i || return

	unset -v args || return

	readonly device_pathnames || return

	#endregion

	#region checking args

	local device_pathname || return

	for device_pathname in "${device_pathnames[@]}"; do
		if [ ! -e "$device_pathname" ]; then
			printf '%s: %s: no such file\n' "${FUNCNAME[0]}" "$device_pathname" >&2
			return 24
		fi
	done

	unset -v device_pathname || return

	#endregion

	#region checking color support

	local color_supported || return
	color_supported=false || return

	if is_color_supported 2; then
		color_supported=true || return
	fi

	readonly color_supported || return

	#endregion

	#region pretty device pathnames

	local -a pretty_device_pathnames || return
	pretty_device_pathnames=() || return

	local device_pathname || return
	for device_pathname in "${device_pathnames[@]}"; do
		local pretty_device_pathname || return

		if command -v pretty_quote > '/dev/null'; then
			pretty_device_pathname="$(pretty_quote "$device_pathname")" || return
		elif command -v quote > '/dev/null'; then
			pretty_device_pathname="$(quote "$device_pathname")" || return
		else
			pretty_device_pathname="'$device_pathname'" || return
		fi

		if $color_supported; then
			pretty_device_pathname="$(tput setaf 3)${pretty_device_pathname}$(tput sgr0)" || return
		fi

		pretty_device_pathnames+=("$pretty_device_pathname") || return

		unset -v pretty_device_pathname || return
	done
	unset -v device_pathname || return

	readonly pretty_device_pathnames

	#endregion

	#region yeet & yeeted

	local yeet yeeted || return
	yeet='yeet' || return
	yeeted='yeeted' || return

	if $color_supported; then
		yeet="$(tput sitm)${yeet}$(tput ritm)" || return
		yeeted="$(tput sitm)${yeeted}$(tput ritm)" || return
	fi

	readonly yeeted yeet || return

	#endregion

	#region building prompt message

	local prompt_msg || return
	prompt_msg="Going to $yeet the device" || return

	if ((${#pretty_device_pathnames[@]} != 1)); then
		prompt_msg+='s' || return
	fi

	local -i i || return
	for ((i = 0; i < ${#pretty_device_pathnames[@]}; ++i)); do
		local pretty_device_pathname || return
		pretty_device_pathname="${pretty_device_pathnames[i]}" || return

		if ((i > 0)); then
			if (((i + 1) == ${#pretty_device_pathnames[@]})); then
				prompt_msg+=' and' || return
			else
				prompt_msg+=',' || return
			fi
		fi

		prompt_msg+=" $pretty_device_pathname" || return

		unset -v pretty_device_pathname || return
	done
	unset -v i || return

	prompt_msg+='. Continue? [y/N] '
	readonly prompt_msg

	#endregion

	#region prompting

	local ans || return
	read -rp "$prompt_msg" ans ||
		{ ans='n' || return; }

	case "$ans" in
		(['yY']*)
			# continue
			;;
		(*)
			printf 'Aborted.\n' >&2
			return 48
			;;
	esac

	unset -v ans || return

	#endregion

	#region doing the yeeting

	local -i i || return
	for ((i = 0; i < ${#device_pathnames[@]}; ++i)); do
		printf '\n' >&2

		local device_pathname || return
		device_pathname="${device_pathnames[i]}" || return

		local pretty_device_pathname || return
		pretty_device_pathname="${pretty_device_pathnames[i]}" || return

		if findmnt --source "$device_pathname" > '/dev/null'; then
			try_as_root umount -- "$device_pathname" || return
		fi

		if command -v eject > '/dev/null'; then
			try_as_root eject -- "$device_pathname" ||
				{
					# shellcheck disable=2016
					printf 'Failed to eject device %s using `device`. Ignoring and moving on.\n' "$pretty_device_pathname" >&2
				}
		fi

		try_as_root udisksctl power-off --block-device="$device_pathname" || return

		printf 'Successfully %s the device %s.\n' "$yeeted" "$pretty_device_pathname" >&2 || return

		unset -v pretty_device_pathname \
		         device_pathname || return
	done

	#endregion
}

#region completion

function _yeet() {
	#region getting available devices

	local -a device_pathnames || return
	device_pathnames=('/dev/sd'?*) || return

	if ((${#device_pathnames[@]} == 1)) && [ "${device_pathnames[0]}" = '/dev/sd?*' ]; then
		device_pathnames=() || return
	fi

	readonly device_pathnames || return

	#endregion

	local cword || return
	cword="${COMP_WORDS[COMP_CWORD]}" || return
	readonly cword || return

	local -a words || return
	words=("${device_pathnames[@]}") || return

	if ((${#cword} == 1)); then
		local device_pathname || return

		for device_pathname in "${device_pathnames[@]}"; do
			if [[ "$device_pathname" =~ ^'/dev/sd'(.)$ ]]; then
				words+=("${BASH_REMATCH[1]}") || return
			fi
		done

		unset -v device_pathname || return
	fi

	if [[ "$cword" =~ ^'sd' ]]; then
		local device_pathname || return

		for device_pathname in "${device_pathnames[@]}"; do
			words+=("${device_pathname#'/dev/'}") || return
		done

		unset -v device_pathname || return
	fi

	# shellcheck disable=2207
	COMPREPLY=($(compgen -W "${words[*]}" -- "$cword"))
}

complete -F _yeet yeet

#endregion
