# SPDX-License-Identifier: CC0-1.0

if command -v doas > '/dev/null' && command -v _command > '/dev/null'; then
	complete -F _command doas
fi
