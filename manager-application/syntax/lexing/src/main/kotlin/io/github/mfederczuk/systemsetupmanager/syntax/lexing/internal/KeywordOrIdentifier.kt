/*
 * Copyright (c) 2025 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.syntax.lexing.internal

import io.github.mfederczuk.systemsetupmanager.syntax.patterns.Identifier.Companion.isIdentifierPartOrEnd
import io.github.mfederczuk.systemsetupmanager.syntax.patterns.Identifier.Companion.isIdentifierStart
import io.github.mfederczuk.systemsetupmanager.syntax.token.Token

private val keywordStartChars: Set<Char> = Token.Keyword.entries
	.mapTo(HashSet(Token.Keyword.entries.size)) { keyword: Token.Keyword ->
		keyword.toSourceCode()[0]
	}

private val keywordPartOrEndChars: Set<Char> = Token.Keyword.entries
	.flatMapTo(hashSetOf()) { keyword: Token.Keyword ->
		keyword.toSourceCode().drop(1).toList()
	}

internal fun Char.isKeywordOrIdentifierStart(): Boolean {
	return this.isIdentifierStart() || (this in keywordStartChars)
}

internal fun Char.isKeywordOrIdentifierPartOrEnd(): Boolean {
	return this.isIdentifierPartOrEnd() || (this in keywordPartOrEndChars)
}
