# SPDX-License-Identifier: CC0-1.0

if ! command -v git > '/dev/null' || ! command -v git-graph > '/dev/null'; then
	return
fi

# for command usage, i.e.: `git graph`
function _git_graph() {
	local cmd

	for cmd in git_log  __git_log_main  _git_log; do
		if ! command -v $cmd > '/dev/null'; then
			continue
		fi

		$cmd "$@"
		return
	done
}

if command -v __git_complete > '/dev/null'; then
	# for direct usage, i.e.: `git-graph`
	__git_complete git-graph git_log

	if [[ "$(alias graph 2> '/dev/null')" =~ ^'alias graph='\''git'[' -']'graph'\'$ ]]; then
		# for alias usage, i.e.: `graph`
		__git_complete graph git_graph
	fi
fi
