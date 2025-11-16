/*
 * Copyright (c) 2025 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.token

import kotlinx.collections.immutable.ImmutableList
import kotlinx.collections.immutable.ImmutableSet
import kotlinx.collections.immutable.adapters.ImmutableSetAdapter
import kotlinx.collections.immutable.persistentListOf
import java.util.EnumSet

public sealed class Token {

	public abstract fun toSourceCode(): String

	public sealed class Known : Token()
	public sealed class NonWhitespaceNorLineComment : Known()
	public sealed class WhitespaceOrLineComment : Known()

	public sealed class Keyword(private val sourceCode: String) : NonWhitespaceNorLineComment() {

		override fun toSourceCode(): String {
			return this.sourceCode
		}

		public data object Import : Keyword("import")
		public data object Task : Keyword("task")
		public data object Copy : Keyword("copy")
		public data object To : Keyword("to")

		public companion object {

			public val entries: ImmutableList<Keyword> = persistentListOf(Import, Task, Copy, To)
		}
	}

	public data class Identifier(public val identifierString: String) : NonWhitespaceNorLineComment() {

		init {
			require(identifierString.isNotEmpty())
			require(identifierString[0].isIdentifierStart())
			require(identifierString.drop(1).all { it.isIdentifierPartOrEnd() })
		}

		override fun toSourceCode(): String {
			return this.identifierString
		}

		public fun <R> validate(
			ifLegal: () -> R,
			ifIllegal: (ImmutableSet<IllegalIdentifierProblem>) -> R,
		): R {
			val illegalIdentifierProblems: ImmutableSet<IllegalIdentifierProblem> =
				this.describeIllegalIdentifierProblems()

			return if (illegalIdentifierProblems.isEmpty()) {
				ifLegal()
			} else {
				ifIllegal(illegalIdentifierProblems)
			}
		}

		private fun describeIllegalIdentifierProblems(): ImmutableSet<IllegalIdentifierProblem> {
			val problems: EnumSet<IllegalIdentifierProblem> =
				EnumSet.noneOf(IllegalIdentifierProblem::class.java)

			if (this.identifierString.endsWith("_")) {
				problems += IllegalIdentifierProblem.EndsWithUnderscore
			}

			if (this.identifierString.startsWith("_")) {
				problems += IllegalIdentifierProblem.StartsWithUnderscore
			}

			if ("__" in this.identifierString) {
				problems += IllegalIdentifierProblem.ContainsDoubleUnderscore
			}

			if (this.identifierString.any { it in 'A'..'Z' }) {
				problems += IllegalIdentifierProblem.ContainsAsciiUppercaseChars
			}

			if (this.identifierString.any { it.isLetterOrLetterNumber() && (it !in 'A'..'Z') && (it !in 'a'..'z') }) {
				problems += IllegalIdentifierProblem.ContainsNonAsciiLetter
			}

			// This mutable EnumSet is neither leaked outside of this function (other than here) nor will it ever be
			// modified beyond this point, so it's safe to wrap it in an immutable set adapter.
			return ImmutableSetAdapter(problems)
		}

		public companion object {

			public fun Char.isIdentifierStart(): Boolean {
				return this.isLetterOrLetterNumber() || (this == '_')
			}

			public fun Char.isIdentifierPartOrEnd(): Boolean {
				return this.isLetterOrLetterNumber() || (this == '_') || (this in '0'..'9')
			}

			private fun Char.isLetterOrLetterNumber(): Boolean {
				return this.isLetter() || (this.category == CharCategory.LETTER_NUMBER)
			}
		}
	}

	public data class StringLiteral(
		public val contents: String,
		public val isTerminated: Boolean,
	) : NonWhitespaceNorLineComment() {

		init {
			require('"' !in contents)
			require('\n' !in contents)
		}

		override fun toSourceCode(): String {
			return '"' + this.contents + (if (this.isTerminated) "\"" else "")
		}
	}

	public sealed class Brace(private val sourceCode: Char) : NonWhitespaceNorLineComment() {

		override fun toSourceCode(): String {
			return this.sourceCode.toString()
		}

		public data object Open : Brace('{')
		public data object Closed : Brace('}')
	}

	public data object DoubleColon : NonWhitespaceNorLineComment() {

		override fun toSourceCode(): String {
			return "::"
		}
	}

	public data class Whitespace(private val sourceCode: String) : WhitespaceOrLineComment() {

		init {
			require(sourceCode.isNotEmpty())
			require(sourceCode.all(Char::isTokenWhitespace))
		}

		override fun toSourceCode(): String {
			return this.sourceCode
		}
	}

	public data class LineComment(public val commentText: String) : WhitespaceOrLineComment() {

		init {
			require('\n' !in commentText)
		}

		override fun toSourceCode(): String {
			return "#${this.commentText}"
		}
	}

	public data class Unknown(private val sourceCode: String) : Token() {

		init {
			require(sourceCode.isNotEmpty())
		}

		override fun toSourceCode(): String {
			return this.sourceCode
		}
	}
}
