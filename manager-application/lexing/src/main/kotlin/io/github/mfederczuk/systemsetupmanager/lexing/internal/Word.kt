/*
 * Copyright (c) 2025 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.lexing.internal

import io.github.mfederczuk.systemsetupmanager.token.Token
import io.github.mfederczuk.systemsetupmanager.token.Token.Identifier.Companion.isIdentifierPartOrEnd
import io.github.mfederczuk.systemsetupmanager.token.Token.Identifier.Companion.isIdentifierStart

private val keywordStartChars: Set<Char> = Token.Keyword.entries
	.mapTo(HashSet(Token.Keyword.entries.size)) { keyword: Token.Keyword ->
		keyword.toSourceCode()[0]
	}

private val keywordPartOrEndChars: Set<Char> = Token.Keyword.entries
	.flatMapTo(hashSetOf()) { keyword: Token.Keyword ->
		keyword.toSourceCode().drop(1).map { it }
	}

// TODO: Historically, the term "word" is used for this concept (keyword, identifier, etc. A sequence of
//       alphanumeric characters + underscore, but that *doesn't* start with a numeric character), but it can be kind of
//       confusing, since with underscores or casing (camelCase, PascalCase) a "word" can contain several actual words.
//       Find a better name for this concept.

internal fun Char.isWordStart(): Boolean {
	return this.isIdentifierStart() || (this in keywordStartChars)
}

internal fun Char.isWordPartOrEnd(): Boolean {
	return this.isIdentifierPartOrEnd() || (this in keywordPartOrEndChars)
}
