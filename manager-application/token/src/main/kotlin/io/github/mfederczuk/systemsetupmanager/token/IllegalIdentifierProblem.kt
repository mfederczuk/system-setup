/*
 * Copyright (c) 2025 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.token

public enum class IllegalIdentifierProblem {
	EndsWithUnderscore,
	StartsWithUnderscore,
	ContainsDoubleUnderscore,
	ContainsAsciiUppercaseChars,
	ContainsNonAsciiLetter,
	;

	// The fact that the severity is the same value as the ordinal is an implementation detail.
	// Don't rely on these two values always being the same!
	public val severity: Int by this::ordinal
}
