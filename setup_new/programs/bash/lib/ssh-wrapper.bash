# Copyright (c) 2025 Michael Federczuk
# SPDX-License-Identifier: MPL-2.0 AND Apache-2.0

if ! command -v ssh > '/dev/null'; then
	return
fi

function ssh() {
	local term || return
	term="${TERM-}" || return

	if [ "$term" != 'xterm-ghostty' ]; then
		command ssh "$@"
		return
	fi

	TERM='xterm-256color' command ssh "$@"
}
