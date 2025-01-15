# SPDX-License-Identifier: CC0-1.0

if ! command -v git > '/dev/null' || ! command -v git-sync > '/dev/null'; then
	return
fi

# for command usage, i.e.: `git sync`
function _git_sync() {
	compopt +o bashdefault +o default

	if ((COMP_CWORD == 2)); then
		if git --no-pager rev-parse 2> '/dev/null'; then
			__gitcomp "$(git --no-pager remote)"
		fi

		return
	fi

	__gitcomp
}

# for direct usage, i.e.: `git-sync`
if command -v __git_complete > '/dev/null'; then
	function _git_sync_completion() {
		if ((COMP_CWORD == 1)); then
			if git --no-pager rev-parse 2> '/dev/null'; then
				__gitcomp "$(git --no-pager remote)"
			fi

			return
		fi

		__gitcomp
	}

	__git_complete git-sync _git_sync_completion
	compopt +o bashdefault +o default git-sync
else
	function _git_sync_completion() {
		if ((COMP_CWORD == 1)); then
			if git --no-pager rev-parse 2> '/dev/null'; then
				local remotes
				remotes="$(git --no-pager remote)"

				mapfile -t COMPREPLY < <(compgen -W "$remotes" -- "$2")
			fi

			return
		fi

		COMPREPLY=()
	}

	complete -F _git_sync_completion git-sync
fi
