# SPDX-License-Identifier: CC0-1.0

if command -v alert > '/dev/null' && command -v _command > '/dev/null'; then
	complete -F _command alert
fi
