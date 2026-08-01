/*
 * Copyright (c) 2026 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.syntax.lexing

import io.github.mfederczuk.systemsetupmanager.syntax.patterns.Identifier.Companion.toIdentifier
import io.github.mfederczuk.systemsetupmanager.syntax.token.Token
import kotlinx.collections.immutable.ImmutableList
import kotlinx.collections.immutable.toImmutableList
import kotlin.test.Test
import kotlin.test.assertEquals

private val Space: Token.Whitespace = Token.Whitespace(" ")
private val Newline: Token.Whitespace = Token.Whitespace("\n")
private val Tab: Token.Whitespace = Token.Whitespace("\t")

class LexingTest {

	@Test
	fun `Various strings lex correctly`() {
		test("", expectedTokens = emptyArray())

		test("import", Token.Keyword.Import)

		test("task", Token.Keyword.Task)

		test("copy", Token.Keyword.Copy)

		test("to", Token.Keyword.To)

		test("foo", Token.Identifier(unwrapped = "foo".toIdentifier()))

		test("\"foo\"", Token.StringLiteral(contents = "foo", isTerminated = true))
		test("\"foo", Token.StringLiteral(contents = "foo", isTerminated = false))

		test("{", Token.Brace.Open)
		test("}", Token.Brace.Closed)

		test("::", Token.DoubleColon)

		test("  \t\n  ", Token.Whitespace(sourceCode = "  \t\n  "))

		test("# foo bar", Token.LineComment(commentText = " foo bar"))

		test(
			"""
			import "foo"

			task bar {
				copy "source" to "target"
				# I'm a comment!
				"foo"::baz
			}
			""".trimIndent(),
			// region import "foo"
			Token.Keyword.Import,
			Space,
			Token.StringLiteral(contents = "foo", isTerminated = true),
			// endregion
			Newline + Newline,
			// region task bar {
			Token.Keyword.Task,
			Space,
			Token.Identifier(unwrapped = "bar".toIdentifier()),
			Space,
			Token.Brace.Open,
			// endregion
			Newline + Tab,
			// region copy "source" to "target"
			Token.Keyword.Copy,
			Space,
			Token.StringLiteral(contents = "source", isTerminated = true),
			Space,
			Token.Keyword.To,
			Space,
			Token.StringLiteral(contents = "target", isTerminated = true),
			// endregion
			Newline + Tab,
			Token.LineComment(commentText = " I'm a comment!"),
			Newline + Tab,
			// region "foo"::baz
			Token.StringLiteral(contents = "foo", isTerminated = true),
			Token.DoubleColon,
			Token.Identifier(unwrapped = "baz".toIdentifier()),
			// endregion
			Newline,
			Token.Brace.Closed,
		)
	}
}

private fun test(inputString: String, vararg expectedTokens: Token) {
	val expectedTokensList: ImmutableList<Token> = expectedTokens.toImmutableList()
	assertEquals(expectedTokensList, inputString.tokenize())
}

private fun String.tokenize(): ImmutableList<Token> {
	return this.asSequence().tokenize().toImmutableList()
}

private operator fun Token.Whitespace.plus(other: Token.Whitespace): Token.Whitespace {
	return Token.Whitespace(sourceCode = this.toSourceCode() + other.toSourceCode())
}
