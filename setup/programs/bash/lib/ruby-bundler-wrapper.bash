# Copyright (c) 2025 Michael Federczuk
# SPDX-License-Identifier: MPL-2.0 AND Apache-2.0

if ! command -v _ruby_bundler_wrapper > '/dev/null'; then
	return
fi

if command -v bundle > '/dev/null'; then
	function bundle() {
		_ruby_bundler_wrapper bundle "$@"
	}
fi

if command -v bundler > '/dev/null'; then
	function bundler() {
		_ruby_bundler_wrapper bundler "$@"
	}
fi
