# Copyright (c) 2023 Michael Federczuk
# SPDX-License-Identifier: MPL-2.0 AND Apache-2.0

if ! command -v trace_cmd > '/dev/null'; then
	return
fi

function check-name() {
	trace_cmd type -a "$1"

	if command -v command_not_found_handle > '/dev/null'; then
		printf '\n'
		trace_cmd command_not_found_handle "$1"
	fi

	printf '\n'
	if command -v dnf > '/dev/null'; then
		trace_cmd dnf search "$1"
	else
		printf 'dnf is not installed; cannot search for dnf package\n'
	fi

	printf '\n'
	if command -v apt > '/dev/null'; then
		trace_cmd apt list "$1"

		printf '\n'
		trace_cmd apt list "*$1*"
	else
		printf 'apt is not installed; cannot search for apt package\n'
	fi

	printf '\n'
	if command -v flatpak > '/dev/null'; then
		trace_cmd flatpak search "$1"
	else
		printf 'flatpak is not installed; cannot search for flatpak package\n'
	fi

	printf '\n'
	if command -v snap > '/dev/null'; then
		trace_cmd snap find "$1"
	else
		printf 'snapd is not installed; cannot search for snap package\n'
	fi

	printf '\n'
	if command -v npm > '/dev/null'; then
		trace_cmd npm search "$1"
	else
		printf 'npm is not installed; cannot search for npm package\n'
	fi
}
