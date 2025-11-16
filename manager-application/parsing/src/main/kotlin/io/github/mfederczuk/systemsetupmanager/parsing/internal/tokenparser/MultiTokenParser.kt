/*
 * Copyright (c) 2025 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.parsing.internal.tokenparser

import io.github.mfederczuk.systemsetupmanager.cst.Node
import io.github.mfederczuk.systemsetupmanager.parsing.internal.utils.iterator.BufferedIterator
import io.github.mfederczuk.systemsetupmanager.token.Token
import kotlinx.collections.immutable.ImmutableList
import kotlinx.collections.immutable.toImmutableList

// TODO: rename, something like "first of multiple"

internal fun <N : Node> multiTokenParserOf(vararg parsers: TokenParser<N>): TokenParser<N> {
	return MultiTokenParser(parsers = parsers.toImmutableList())
}

private class MultiTokenParser<out N : Node>(private val parsers: ImmutableList<TokenParser<N>>) : TokenParser<N> {

	override fun parseNext(tokens: BufferedIterator<Token>): N? {
		// TODO: once error/warning reporting is added, the errors/warnings of parsed that failed must not be reported
		//       to the caller

		for (parser: TokenParser<N> in this.parsers) {
			val element: N? = parser.parseNext(tokens)

			if (element != null) {
				return element
			}
		}

		return null
	}
}
