/*
 * Copyright (c) 2026 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.syntax.parsing.internal.tokenparser

import io.github.mfederczuk.systemsetupmanager.syntax.cst.EnclosedNodesList
import io.github.mfederczuk.systemsetupmanager.syntax.cst.Node
import io.github.mfederczuk.systemsetupmanager.syntax.parsing.internal.thenWhitespacesOrLineComments
import io.github.mfederczuk.systemsetupmanager.syntax.parsing.internal.utils.iterator.BufferedIterator
import io.github.mfederczuk.systemsetupmanager.syntax.parsing.internal.utils.iterator.buffered
import io.github.mfederczuk.systemsetupmanager.syntax.token.Token
import kotlinx.collections.immutable.persistentListOf

@FunctionalInterface
internal fun interface TokenParser<out N : Node> {

	// TODO: return result: none/unexpected(<how many tokens attempted to be read>) | error | success

	/**
	 * Parses the next tokens supplied by the iterator [tokens] and either returns an instance of [N], in which case
	 * the necessary tokens will be consumed from the iterator, or returns `null`, in which case any consumed tokens
	 * will be restored back to the iterator with
	 * the function [BufferedIterator.pushToBuffer()][BufferedIterator.pushToBuffer].
	 */
	fun parseNext(tokens: BufferedIterator<Token>): N?

	companion object {

		fun <N : Node> Iterator<Token>.parseRemainingWith(parser: TokenParser<N>): EnclosedNodesList<N> {
			val builder: EnclosedNodesList.Builder<N> = EnclosedNodesList.Builder()

			val buffered: BufferedIterator<Token> = this.buffered()

			builder.addNonNode(buffered.thenWhitespacesOrLineComments())

			while (buffered.hasNext()) {
				val node: N? = parser.parseNext(buffered)
				if (node != null) {
					builder.addNode(node)
				} else {
					// TODO: report error "unexpected token"
					// TODO: The parser could return how many tokens it tries to read to disambiguate its node
					//       (most of the time it should only be 1? only one i can think of that might be ambiguous
					//        later on is the task execution because it starts with a string literal)
					//       then we can report these tokens as unexpected?
					val token: Token = buffered.next()

					builder.addNonNode(persistentListOf(token))
				}

				builder.addNonNode(buffered.thenWhitespacesOrLineComments())
			}

			return builder.build()
		}
	}
}
