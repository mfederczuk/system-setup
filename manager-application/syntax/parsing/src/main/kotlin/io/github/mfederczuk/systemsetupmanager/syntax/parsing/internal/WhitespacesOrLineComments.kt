/*
 * Copyright (c) 2025 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.syntax.parsing.internal

import io.github.mfederczuk.systemsetupmanager.syntax.parsing.internal.utils.iterator.BufferedIterator
import io.github.mfederczuk.systemsetupmanager.syntax.token.Token
import kotlinx.collections.immutable.ImmutableList
import kotlinx.collections.immutable.PersistentList
import kotlinx.collections.immutable.persistentListOf

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
