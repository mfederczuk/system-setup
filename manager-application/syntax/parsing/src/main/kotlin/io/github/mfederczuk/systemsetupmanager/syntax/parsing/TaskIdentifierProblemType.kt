/*
 * Copyright (c) 2026 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.syntax.parsing

import io.github.mfederczuk.systemsetupmanager.syntax.patterns.Identifier
import kotlinx.collections.immutable.ImmutableSet
import kotlinx.collections.immutable.adapters.ImmutableSetAdapter
import java.util.EnumSet

public enum class IllegalTaskIdentifierProblem {
	EndsWithUnderscore,
	StartsWithUnderscore,
	ContainsDoubleUnderscore,
	ContainsAsciiUppercaseChars,
	ContainsNonAsciiCharacter,
	;

	// The fact that the severity is the same value as the ordinal is an implementation detail.
	// Don't rely on these two values always being the same!
	public val severity: Int by this::ordinal

	public companion object {

		public fun Identifier.determineIllegalTaskIdentifierProblems(): ImmutableSet<IllegalTaskIdentifierProblem> {
			val problems: EnumSet<IllegalTaskIdentifierProblem> =
				EnumSet.noneOf(IllegalTaskIdentifierProblem::class.java)

			val identifierString: String = this.toString()

			if (identifierString.startsWith("_")) {
				problems += StartsWithUnderscore
			}

			if (identifierString.endsWith("_")) {
				problems += EndsWithUnderscore
			}

			if (identifierString.any { !(it.isAscii()) }) {
				problems += ContainsNonAsciiCharacter
			}

			if (identifierString.any { it in 'A'..'Z' }) {
				problems += ContainsAsciiUppercaseChars
			}

			if ("__" in identifierString) {
				problems += ContainsDoubleUnderscore
			}

			// This mutable EnumSet is neither leaked outside of this function (other than here) nor will it ever be
			// modified beyond this point, so it's safe to wrap it in an immutable set adapter.
			return ImmutableSetAdapter(problems)
		}
	}
}

private fun Char.isAscii(): Boolean {
	return this.code in (0..0x7F)
}
