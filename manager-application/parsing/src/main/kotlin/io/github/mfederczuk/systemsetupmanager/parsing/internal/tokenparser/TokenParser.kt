/*
 * Copyright (c) 2025 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.parsing.internal.tokenparser

import io.github.mfederczuk.systemsetupmanager.cst.EnclosedNodesList
import io.github.mfederczuk.systemsetupmanager.cst.Node
import io.github.mfederczuk.systemsetupmanager.parsing.internal.thenWhitespacesOrLineComments
import io.github.mfederczuk.systemsetupmanager.parsing.internal.utils.iterator.BufferedIterator
import io.github.mfederczuk.systemsetupmanager.parsing.internal.utils.iterator.buffered
import io.github.mfederczuk.systemsetupmanager.token.Token
import kotlinx.collections.immutable.ImmutableList
import kotlinx.collections.immutable.persistentListOf

@FunctionalInterface
internal fun interface TokenParser<out N : Node> {

	/**
	 * Parses the next tokens supplied by the iterator [tokens] and either returns an instance of [N], in which case
	 * the necessary tokens will be consumed from the iterator, or returns `null`, in which case any consumed tokens
	 * will be restored back to the iterator with
	 * the function [BufferedIterator.pushToBuffer()][BufferedIterator.pushToBuffer].
	 */
	// none | error | success
	fun parseNext(tokens: BufferedIterator<Token>): N?

	companion object {

		fun <N : Node> Iterator<Token>.parseRemainingWith(parser: TokenParser<N>): EnclosedNodesList<N> {
			val builder: EnclosedNodesList.Builder<N> = EnclosedNodesList.Builder()

			val buffered: BufferedIterator<Token> = this.buffered()

			fun parseNext() {
				val node: N? = parser.parseNext(buffered)

				if (node != null) {
					builder.addNode(node)
					return
				}

				// TODO: report error "unexpected token", but it also can be whitespace or line comments, these should
				//       not be reported
				val token: Token = buffered.next()

				builder.addNonNode(persistentListOf(token))
			}

			if (buffered.hasNext()) {
				parseNext()
			}

			do {
				if (buffered.hasNext()) {
					val nonNodeTokens: ImmutableList<Token.WhitespaceOrLineComment> =
						buffered.thenWhitespacesOrLineComments()

					builder.addNonNode(nonNodeTokens)
				}

				if (!(buffered.hasNext())) {
					break
				}

				parseNext()
			} while (buffered.hasNext())

			return builder.build()
		}
	}
}
