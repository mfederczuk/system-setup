/*
 * Copyright (c) 2026 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.syntax.patterns

@JvmInline
public value class Identifier private constructor(private val identifierString: String) {

	init {
		require(identifierString.isIdentifier())
	}

	override fun toString(): String {
		return this.identifierString
	}

	public companion object {

		public fun Char.isIdentifierStart(): Boolean {
			return this.isLetterOrLetterNumber() || (this == '_')
		}

		public fun Char.isIdentifierPartOrEnd(): Boolean {
			return this.isLetterOrLetterNumber() || (this == '_') || (this in '0'..'9')
		}

		public fun String.toIdentifierOrNull(): Identifier? {
			return if (this.isIdentifier()) {
				Identifier(identifierString = this)
			} else {
				null
			}
		}

		public fun String.toIdentifier(): Identifier {
			return requireNotNull(this.toIdentifierOrNull()) {
				"Invalid identifier: $this"
			}
		}

		private fun String.isIdentifier(): Boolean {
			return this.isNotEmpty() &&
				this[0].isIdentifierStart() &&
				this.drop(1).all { it.isIdentifierPartOrEnd() }
		}
	}
}

private fun Char.isLetterOrLetterNumber(): Boolean {
	return this.isLetter() || (this.category == CharCategory.LETTER_NUMBER)
}
