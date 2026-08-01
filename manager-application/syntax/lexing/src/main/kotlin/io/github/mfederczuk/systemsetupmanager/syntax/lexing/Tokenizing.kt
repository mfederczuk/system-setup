/*
 * Copyright (c) 2026 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.syntax.lexing

import io.github.mfederczuk.systemsetupmanager.syntax.lexing.internal.Lexer
import io.github.mfederczuk.systemsetupmanager.syntax.token.Token
import kotlinx.collections.immutable.ImmutableList
import java.io.Reader

public fun Sequence<Char>.tokenize(): Sequence<Token> {
	return sequence {
		val lexer = Lexer(charIterator = this@tokenize.iterator())

		while (true) {
			val tokens: ImmutableList<Token> = lexer.nextTokens()

			if (tokens.isNotEmpty()) {
				yieldAll(tokens)
			} else {
				break
			}
		}
	}
}

public fun Reader.tokenize(): Sequence<Token> {
	return this.asCharSequence().tokenize()
}

private fun Reader.asCharSequence(): Sequence<Char> {
	return sequence {
		while (true) {
			val charAsInt: Int = this@asCharSequence.read()

			if (charAsInt !in 0..0xFFFF) {
				break
			}

			yield(charAsInt.toChar())
		}
	}
}
