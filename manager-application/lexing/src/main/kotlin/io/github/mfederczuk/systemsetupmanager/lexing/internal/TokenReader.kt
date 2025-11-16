/*
 * Copyright (c) 2025 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.lexing.internal

import io.github.mfederczuk.systemsetupmanager.token.Token
import io.github.mfederczuk.systemsetupmanager.token.isTokenWhitespace
import kotlinx.collections.immutable.ImmutableList
import kotlinx.collections.immutable.PersistentList
import kotlinx.collections.immutable.persistentListOf
import java.io.Reader

internal class TokenReader(private val charReader: Reader) {

	private var bufferedChar: Char? = null

	fun read(): ImmutableList<Token> {
		return context(UnknownTokenBuilder()) { this.read() }
	}

	context(unknownTokenBuilder: UnknownTokenBuilder)
	private fun read(): ImmutableList<Token> {
		while (true) {
			val firstChar: Char = this.readChar()
				?: return persistentListOfNotNull(unknownTokenBuilder.build())

			when (firstChar) {
				'"' -> return this.continueReadingStringLiteral()

				'{' -> return finishReadingToken(Token.Brace.Open)
				'}' -> return finishReadingToken(Token.Brace.Closed)

				':' -> {
					val secondChar: Char? = this.readChar()

					if (secondChar == ':') {
						return finishReadingToken(Token.DoubleColon)
					}

					this.bufferedChar = secondChar
					unknownTokenBuilder.append(firstChar)
				}

				'#' -> return this.continueReadingComment()
			}

			if (firstChar.isWordStart()) {
				return this.continueReadingWord(firstChar)
			}

			if (firstChar.isTokenWhitespace()) {
				return this.continueReadingWhitespace(firstChar)
			}

			unknownTokenBuilder.append(firstChar)
		}
	}

	context(unknownTokenBuilder: UnknownTokenBuilder)
	private fun continueReadingStringLiteral(): ImmutableList<Token> {
		val contentsBuilder = StringBuilder()

		fun finishReadingToken(isTerminated: Boolean): ImmutableList<Token> {
			val token = Token.StringLiteral(contentsBuilder.toString(), isTerminated)
			return finishReadingToken(token)
		}

		while (true) {
			val char: Char? = this.readChar()

			if (char == '"') {
				return finishReadingToken(isTerminated = true)
			}

			if ((char != null) && (char != '\n')) {
				contentsBuilder.append(char)
				continue
			}

			this.bufferedChar = char

			return finishReadingToken(isTerminated = false)
		}
	}

	context(unknownTokenBuilder: UnknownTokenBuilder)
	private fun continueReadingComment(): ImmutableList<Token> {
		val commentTextBuilder = StringBuilder()

		while (true) {
			val char: Char? = this.readChar()

			if ((char != null) && (char != '\n')) {
				commentTextBuilder.append(char)
				continue
			}

			this.bufferedChar = char

			return finishReadingToken(Token.LineComment(commentTextBuilder.toString()))
		}
	}

	context(unknownTokenBuilder: UnknownTokenBuilder)
	private fun continueReadingWord(firstChar: Char): ImmutableList<Token> {
		require(firstChar.isWordStart())

		val wordStringBuilder = StringBuilder()
		wordStringBuilder.append(firstChar)

		while (true) {
			val char: Char? = this.readChar()

			if ((char != null) && char.isWordPartOrEnd()) {
				wordStringBuilder.append(char)
				continue
			}

			this.bufferedChar = char

			val wordString: String = wordStringBuilder.toString()

			val token: Token.Known = Token.Keyword.entries
				.firstOrNull { keyword: Token.Keyword ->
					keyword.toSourceCode() == wordString
				}
				?: Token.Identifier(wordString)

			return finishReadingToken(token)
		}
	}

	context(unknownTokenBuilder: UnknownTokenBuilder)
	private fun continueReadingWhitespace(firstChar: Char): ImmutableList<Token> {
		require(firstChar.isTokenWhitespace())

		val whitespaceStringBuilder = StringBuilder()
		whitespaceStringBuilder.append(firstChar)

		while (true) {
			val char: Char? = this.readChar()

			if ((char != null) && char.isTokenWhitespace()) {
				whitespaceStringBuilder.append(char)
				continue
			}

			this.bufferedChar = char

			return finishReadingToken(Token.Whitespace(whitespaceStringBuilder.toString()))
		}
	}

	private fun readChar(): Char? {
		this.bufferedChar?.let {
			this.bufferedChar = null
			return it
		}

		return this.charReader.readOrNull()
	}
}

context(unknownTokenBuilder: UnknownTokenBuilder)
private fun finishReadingToken(token: Token.Known): ImmutableList<Token> {
	return persistentListOfNotNull(unknownTokenBuilder.build(), token)
}

private fun <E : Any> persistentListOfNotNull(vararg elements: E?): PersistentList<E> {
	return persistentListOf<E>().addAll(elements.filterNotNull())
}

private fun Reader.readOrNull(): Char? {
	val charAsInt: Int = this.read()

	if (charAsInt == -1) {
		return null
	}

	return charAsInt.toChar()
}
