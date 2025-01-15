# SPDX-License-Identifier: CC0-1.0

#region checking for required programs

declare __dotfiles_bash_funcs_curlrr__cmd

for __dotfiles_bash_funcs_curlrr__cmd in curl sed; do
	if ! command -v "$__dotfiles_bash_funcs_curlrr__cmd" > '/dev/null'; then
		return
	fi
done

unset -v __dotfiles_bash_funcs_curlrr__cmd

#endregion

#region checking for GNU sed

declare __dotfiles_bash_funcs_curlrr__sed_version_info
__dotfiles_bash_funcs_curlrr__sed_version_info="$(sed --version)" || return

if [[ ! "$__dotfiles_bash_funcs_curlrr__sed_version_info" =~ ^'sed (GNU sed)' ]]; then
	return
fi

unset -v __dotfiles_bash_funcs_curlrr__sed_version_info

#endregion

# 'curlrr' = 'curl request-response'
function curlrr() {
	#region checking for required programs

	local cmd || return

	for cmd in curl sed; do
		if ! command -v "$cmd" > '/dev/null'; then
			printf '%s: %s: program missing\n' "${FUNCNAME[0]}" "$cmd" >&2
			return 27
		fi
	done

	unset -v cmd || return

	#endregion

	curl "$@" --silent --verbose 2>&1 |
		sed -E \
		    -e /'^\* '/d \
		    -e /'^[{}] \[[0-9]+ byte(s)? data]$'/d \
		    -e s/'^[><] '/''/
}
