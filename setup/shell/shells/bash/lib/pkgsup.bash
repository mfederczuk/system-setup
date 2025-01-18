# Copyright (c) 2023 Michael Federczuk
# SPDX-License-Identifier: MPL-2.0 AND Apache-2.0

if ! command -v trace_cmd > '/dev/null'; then
	return
fi

#region distinct package managers

# BASE: <cmd>-up command for system's native package manager

if command -v flatpak > '/dev/null'; then
	function flatpak-up() {
		#region checking for required programs

		local cmd || return

		for cmd in flatpak trace_cmd; do
			if ! command -v "$cmd" > '/dev/null'; then
				printf '%s: %s: program missing\n' "${FUNCNAME[0]}" "$cmd" >&2
				return 27
			fi
		done

		unset -v cmd || return

		#endregion

		if (($# > 0)); then
			printf '%s: too many arguments: %i\n' "${FUNCNAME[0]}" $# >&2
			return 4
		fi

		trace_cmd flatpak update >&2
	}

	complete flatpak-up
fi

if command -v npm > '/dev/null' && command -v try_as_root > '/dev/null'; then
	function npm-up() {
		#region checking for required programs

		local cmd || return

		for cmd in npm trace_cmd try_as_root; do
			if ! command -v "$cmd" > '/dev/null'; then
				printf '%s: %s: program missing\n' "${FUNCNAME[0]}" "$cmd" >&2
				return 27
			fi
		done

		unset -v cmd || return

		#endregion

		if (($# > 0)); then
			printf '%s: too many arguments: %i\n' "${FUNCNAME[0]}" $# >&2
			return 4
		fi

		#region collecting globally installed packages

		local -a packages || return
		packages=() || return

		local line || return

		while read -r line; do
			if [[ ! "$line" =~ ^('├── '|'└── ')(.+)'@'[^'@']+$ ]]; then
				continue
			fi

			packages+=("${BASH_REMATCH[2]}") || return
		done < <(npm list --global --depth=0 |
			         # removes first line
			         tail -n +2)

		unset -v line || return

		readonly packages

		#endregion

		if ((${#packages[@]} == 0)); then
			# no-op
			return
		fi

		trace_cmd npm install --global "${packages[@]}" >&2
	}

	complete npm-up
fi

#endregion

#region pkgsup

declare __dotfiles_bash_funcs_pkgsup__any_up_commands_present
__dotfiles_bash_funcs_pkgsup__any_up_commands_present=false

declare __dotfiles_bash_funcs_pkgsup__up_cmd

for __dotfiles_bash_funcs_pkgsup__up_cmd in {dnf,apt,flatpak,npm}-up; do
	if command -v "$__dotfiles_bash_funcs_pkgsup__up_cmd" > '/dev/null'; then
		__dotfiles_bash_funcs_pkgsup__any_up_commands_present=true
		break
	fi
done

unset -v __dotfiles_bash_funcs_pkgsup__up_cmd

if $__dotfiles_bash_funcs_pkgsup__any_up_commands_present; then
	# shellcheck disable=2120
	function pkgsup() {
		if ! command -v trace_cmd > '/dev/null'; then
			printf '%s: trace_cmd: program missing\n' "${FUNCNAME[0]}" >&2
			return 27
		fi

		if (($# > 0)); then
			printf '%s: too many arguments: %i\n' "${FUNCNAME[0]}" $# >&2
			return 4
		fi

		local -ar package_managers=(
			# BASE: system's native package manager command
			flatpak
			npm
		) || return

		local print_separator || return
		print_separator=false || return

		local package_manager || return
		for package_manager in "${package_managers[@]}"; do
			if ! command -v "$package_manager-up" > '/dev/null'; then
				continue
			fi

			if $print_separator; then
				printf '\n\n\n' >&2 || return
			fi

			print_separator=true || return

			trace_cmd "$package_manager-up" || return
		done
	}

	complete pkgsup
fi

unset -v __dotfiles_bash_funcs_pkgsup__any_up_commands_present

#endregion

#region upshut

if command -v pkgsup > '/dev/null'; then
	function upshut() {
		#region checking for required programs

		local cmd || return

		for cmd in trace_cmd pkgsup; do
			if ! command -v "$cmd" > '/dev/null'; then
				printf '%s: %s: program missing\n' "${FUNCNAME[0]}" "$cmd" >&2
				return 27
			fi
		done

		unset -v cmd || return

		#endregion

		if (($# > 0)); then
			printf '%s: too many arguments: %i\n' "${FUNCNAME[0]}" $# >&2
			return 4
		fi

		trace_cmd pkgsup || return

		printf 'Shutting down in 3 seconds... (Ctrl+C to cancel)\n' >&2 || return
		sleep 3 || return

		if [ -n "${HISTFILE-}" ] && [ ! -e "$HISTFILE" ]; then
			local histfile_parent_dir_pathname || return
			histfile_parent_dir_pathname="$(dirname -- "$HISTFILE" && printf x)" || return
			histfile_parent_dir_pathname="${histfile_parent_dir_pathname%$'\nx'}" || return

			mkdir -p -- "$histfile_parent_dir_pathname" || return

			unset -v histfile_parent_dir_pathname || return
		fi
		history -a || return

		trace_cmd shutdown 0
	}

	complete upshut
fi

#endregion
