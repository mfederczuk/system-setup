/*
 * Copyright (c) 2025 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.lexing

import io.github.mfederczuk.systemsetupmanager.lexing.internal.TokenReader
import io.github.mfederczuk.systemsetupmanager.token.Token
import kotlinx.collections.immutable.ImmutableList
import java.io.Reader

public fun Reader.tokenize(): Sequence<Token> {
	return sequence {
		val stream = TokenReader(charReader = this@tokenize)

		while (true) {
			val tokens: ImmutableList<Token> = stream.read()

			if (tokens.isNotEmpty()) {
				yieldAll(tokens)
			} else {
				break
			}
		}
	}
}
