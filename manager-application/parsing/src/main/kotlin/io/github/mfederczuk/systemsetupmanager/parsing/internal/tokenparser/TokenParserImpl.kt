/*
 * Copyright (c) 2025 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.parsing.internal.tokenparser

import io.github.mfederczuk.systemsetupmanager.cst.Node
import io.github.mfederczuk.systemsetupmanager.parsing.internal.utils.iterator.BufferedIterator
import io.github.mfederczuk.systemsetupmanager.parsing.internal.utils.iterator.restoreOnNull
import io.github.mfederczuk.systemsetupmanager.token.Token

internal fun <N : Node> TokenParser(parseNext: (Iterator<Token>) -> N?): TokenParser<N> {
	return TokenParserImpl(parseNext)
}

private class TokenParserImpl<out N : Node>(private val parseNext: (Iterator<Token>) -> N?) : TokenParser<N> {

	override fun parseNext(tokens: BufferedIterator<Token>): N? {
		return restoreOnNull(tokens) { tokens: Iterator<Token> ->
			this.parseNext(tokens)
		}
	}
}
