/*
 * Copyright (c) 2026 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.syntax.lexing.internal

import io.github.mfederczuk.systemsetupmanager.syntax.patterns.Identifier.Companion.toIdentifier
import io.github.mfederczuk.systemsetupmanager.syntax.token.Token
import io.github.mfederczuk.systemsetupmanager.syntax.token.isTokenWhitespace
import kotlinx.collections.immutable.ImmutableList
import kotlinx.collections.immutable.persistentListOf

internal class Lexer(private val charIterator: Iterator<Char>) {

	private var bufferedChar: Char? = null

	fun nextTokens(): ImmutableList<Token> {
		return context(UnknownTokenBuilder()) { this.nextTokensInternal() }
	}

	context(unknownTokenBuilder: UnknownTokenBuilder)
	private fun nextTokensInternal(): ImmutableList<Token> {
		while (true) {
			val firstChar: Char = this.nextCharOrNull()
				?: return unknownTokenBuilder.build()?.let(::persistentListOf) ?: persistentListOf()

			when (firstChar) {
				'"' -> return this.continueWithStringLiteral()

				'{' -> return finalizeToken(Token.Brace.Open)

				'}' -> return finalizeToken(Token.Brace.Closed)

				':' -> {
					val secondChar: Char? = this.nextCharOrNull()

					if (secondChar == ':') {
						return finalizeToken(Token.DoubleColon)
					}

					this.bufferedChar = secondChar
					unknownTokenBuilder.append(firstChar)
				}

				'#' -> return this.continueWithComment()
			}

			if (firstChar.isKeywordOrIdentifierStart()) {
				return this.continueWithKeywordOrIdentifier(firstChar)
			}

			if (firstChar.isTokenWhitespace()) {
				return this.continueWithWhitespace(firstChar)
			}

			unknownTokenBuilder.append(firstChar)
		}
	}

	context(unknownTokenBuilder: UnknownTokenBuilder)
	private fun continueWithStringLiteral(): ImmutableList<Token> {
		val contentsBuilder = StringBuilder()

		fun finalizeToken(isTerminated: Boolean): ImmutableList<Token> {
			val token = Token.StringLiteral(contentsBuilder.toString(), isTerminated)
			return finalizeToken(token)
		}

		while (true) {
			val char: Char? = this.nextCharOrNull()

			if (char == '"') {
				return finalizeToken(isTerminated = true)
			}

			if ((char != null) && (char != '\n')) {
				contentsBuilder.append(char)
				continue
			}

			this.bufferedChar = char

			return finalizeToken(isTerminated = false)
		}
	}

	context(unknownTokenBuilder: UnknownTokenBuilder)
	private fun continueWithComment(): ImmutableList<Token> {
		val commentTextBuilder = StringBuilder()

		while (true) {
			val char: Char? = this.nextCharOrNull()

			if ((char != null) && (char != '\n')) {
				commentTextBuilder.append(char)
				continue
			}

			this.bufferedChar = char

			return finalizeToken(Token.LineComment(commentTextBuilder.toString()))
		}
	}

	context(unknownTokenBuilder: UnknownTokenBuilder)
	private fun continueWithKeywordOrIdentifier(firstChar: Char): ImmutableList<Token> {
		require(firstChar.isKeywordOrIdentifierStart())

		val keywordOrIdentifierBuilder = StringBuilder()
		keywordOrIdentifierBuilder.append(firstChar)

		while (true) {
			val char: Char? = this.nextCharOrNull()

			if ((char != null) && char.isKeywordOrIdentifierPartOrEnd()) {
				keywordOrIdentifierBuilder.append(char)
				continue
			}

			this.bufferedChar = char

			val keywordOrIdentifierString: String = keywordOrIdentifierBuilder.toString()

			val token: Token.Known = Token.Keyword.entries
				.firstOrNull { keyword: Token.Keyword ->
					keyword.toSourceCode() == keywordOrIdentifierString
				}
				?: Token.Identifier(unwrapped = keywordOrIdentifierString.toIdentifier())

			return finalizeToken(token)
		}
	}

	context(unknownTokenBuilder: UnknownTokenBuilder)
	private fun continueWithWhitespace(firstChar: Char): ImmutableList<Token> {
		require(firstChar.isTokenWhitespace())

		val whitespaceStringBuilder = StringBuilder()
		whitespaceStringBuilder.append(firstChar)

		while (true) {
			val char: Char? = this.nextCharOrNull()

			if ((char != null) && char.isTokenWhitespace()) {
				whitespaceStringBuilder.append(char)
				continue
			}

			this.bufferedChar = char

			return finalizeToken(Token.Whitespace(whitespaceStringBuilder.toString()))
		}
	}

	private fun nextCharOrNull(): Char? {
		this.bufferedChar?.let { bufferedChar: Char ->
			this.bufferedChar = null
			return bufferedChar
		}

		if (!(this.charIterator.hasNext())) {
			return null
		}

		return this.charIterator.next()
	}
}

context(unknownTokenBuilder: UnknownTokenBuilder)
private fun finalizeToken(token: Token.Known): ImmutableList<Token> {
	unknownTokenBuilder.build()?.let { unknownToken: Token.Unknown ->
		return persistentListOf(unknownToken, token)
	}

	return persistentListOf(token)
}
