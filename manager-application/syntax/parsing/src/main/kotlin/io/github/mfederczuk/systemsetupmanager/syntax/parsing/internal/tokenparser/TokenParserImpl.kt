/*
 * Copyright (c) 2026 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.syntax.parsing.internal.tokenparser

import io.github.mfederczuk.systemsetupmanager.syntax.cst.Node
import io.github.mfederczuk.systemsetupmanager.syntax.parsing.internal.utils.iterator.BufferedIterator
import io.github.mfederczuk.systemsetupmanager.syntax.parsing.internal.utils.iterator.onEach
import io.github.mfederczuk.systemsetupmanager.syntax.token.Token
import kotlinx.collections.immutable.toImmutableList

internal fun <N : Node> TokenParser(parseNext: (Iterator<Token>) -> N?): TokenParser<N> {
	return TokenParserImpl(parseNext)
}

private data class TokenParserImpl<out N : Node>(private val parseNext: (Iterator<Token>) -> N?) : TokenParser<N> {

	override fun parseNext(tokens: BufferedIterator<Token>): N? {
		val consumedElements: MutableList<Token> = mutableListOf()
		val teeTokens: Iterator<Token> = tokens
			.onEach(consumedElements::add)

		val node: N? = this.parseNext.invoke(teeTokens)

		if (node == null) {
			tokens.pushToBuffer(consumedElements.toImmutableList())
		}

		return node
	}
}
