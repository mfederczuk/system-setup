# SPDX-License-Identifier: CC0-1.0

if ! command -v git > '/dev/null' || ! command -v __git_complete > '/dev/null'; then
	return
fi

function __bash_completions_git_bash_aliases__complete() {
	local alias complete_func || return
	alias="$1" || return
	complete_func="$2" || return
	readonly complete_func alias

	local type || return
	type="$(type -t -- "$alias")" || return
	readonly type

	if [[ "$type" == 'alias' ]]; then
		__git_complete "$alias" "$complete_func"
	fi
}

# The aliases are defined in the file `setup/programs/bash/aliases.bash`.

__bash_completions_git_bash_aliases__complete addall git_add
__bash_completions_git_bash_aliases__complete adduv git_add
__bash_completions_git_bash_aliases__complete branchall git_branch
__bash_completions_git_bash_aliases__complete graph git_log
__bash_completions_git_bash_aliases__complete gstat git_status

unset -f __bash_completions_git_bash_aliases__complete
