/*
 * Copyright (c) 2025 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.syntax.parsing.internal

import io.github.mfederczuk.systemsetupmanager.syntax.cst.TasksModuleElement.ImportStatement
import io.github.mfederczuk.systemsetupmanager.syntax.parsing.internal.tokenparser.TokenParser
import io.github.mfederczuk.systemsetupmanager.syntax.parsing.internal.utils.iterator.BufferedIterator
import io.github.mfederczuk.systemsetupmanager.syntax.parsing.internal.utils.iterator.buffered
import io.github.mfederczuk.systemsetupmanager.syntax.parsing.internal.utils.iterator.nextOrNull
import io.github.mfederczuk.systemsetupmanager.syntax.token.Token
import kotlinx.collections.immutable.ImmutableList

internal val ImportStatementParser: TokenParser<ImportStatement> =
	TokenParser(Iterator<Token>::parseNextImportStatement)

private fun Iterator<Token>.parseNextImportStatement(): ImportStatement? {
	val importKeywordToken: Token.Keyword.Import = this.startWithImportKeyword() ?: return null

	val buffered: BufferedIterator<Token> = this.buffered()

	val innerTokens: ImmutableList<Token.WhitespaceOrLineComment> = buffered.thenWhitespacesOrLineComments()
	val stringToken: Token.StringLiteral = buffered.thenImportString() ?: return null

	return ImportStatement(importKeywordToken, innerTokens, stringToken)
}

private fun Iterator<Token>.startWithImportKeyword(): Token.Keyword.Import? {
	return this.nextOrNull() as? Token.Keyword.Import
}

private fun Iterator<Token>.thenImportString(): Token.StringLiteral? {
	val token: Token? = this.nextOrNull()

	if (token == null) {
		// TODO: report error "expected a string literal after an `import` keyword "
		return null
	}

	if (token !is Token.StringLiteral) {
		// TODO: report error "unexpected token after the keyword `import`. expected a string literal but got ..."
		return null
	}

	if (!(token.isTerminated)) {
		// TODO: report error "unterminated string"
	}

	return token
}
