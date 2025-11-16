/*
 * Copyright (c) 2025 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.parsing.internal

import io.github.mfederczuk.systemsetupmanager.parsing.internal.utils.iterator.BufferedIterator
import io.github.mfederczuk.systemsetupmanager.token.Token
import kotlinx.collections.immutable.ImmutableList
import kotlinx.collections.immutable.PersistentList
import kotlinx.collections.immutable.persistentListOf

internal inline fun <reified R : Token> BufferedIterator<Token>.then(): ImmutableList<R> {
	val tokens: PersistentList.Builder<R> = persistentListOf<R>().builder()

	while (this.hasNext()) {
		val token: Token = this.next()

		if (token is R) {
			tokens += token
			continue
		}

		this.pushToBuffer(token)
		break
	}

	return tokens.build()
}

internal fun BufferedIterator<Token>.thenList(predicate: (Token) -> Boolean): ImmutableList<Token> {
	val tokens: PersistentList.Builder<Token> = persistentListOf<Token>().builder()

	while (this.hasNext()) {
		val token: Token = this.next()

		if (predicate(token)) {
			tokens += token
			continue
		}

		this.pushToBuffer(token)
		break
	}

	return tokens.build()
}

internal inline fun <R : Any> BufferedIterator<Token>.then(crossinline block: (Token) -> R?): R? {
	if (!(this.hasNext())) {
		return null
	}

	val token: Token = this.next()

	val blockReturnValue: R? = block(token)

	if (blockReturnValue == null) {
		this.pushToBuffer(token)
	}

	return blockReturnValue
}

internal fun BufferedIterator<Token>.thenWhitespacesOrLineComments(): ImmutableList<Token.WhitespaceOrLineComment> {
	val tokens: PersistentList.Builder<Token.WhitespaceOrLineComment> =
		persistentListOf<Token.WhitespaceOrLineComment>().builder()

	while (this.hasNext()) {
		val token: Token = this.next()

		if (token is Token.WhitespaceOrLineComment) {
			tokens += token
			continue
		}

		this.pushToBuffer(token)
		break
	}

	return tokens.build()
}
