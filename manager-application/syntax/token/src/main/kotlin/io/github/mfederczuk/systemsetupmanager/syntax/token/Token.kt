/*
 * Copyright (c) 2025 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.syntax.token

import kotlinx.collections.immutable.ImmutableList
import kotlinx.collections.immutable.persistentListOf

@Suppress("ktlint:standard:blank-line-before-declaration")
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

			// This property is initialized before the data objects, which means that the data object instances are
			// `null` at runtime when this property gets initialized, which is why this property is made lazy.
			public val entries: ImmutableList<Keyword> by lazy(mode = LazyThreadSafetyMode.PUBLICATION) {
				persistentListOf(Import, Task, Copy, To)
			}
		}
	}

	public data class Identifier(
		public val unwrapped: io.github.mfederczuk.systemsetupmanager.syntax.patterns.Identifier,
	) : NonWhitespaceNorLineComment() {

		override fun toSourceCode(): String {
			return this.unwrapped.toString()
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
