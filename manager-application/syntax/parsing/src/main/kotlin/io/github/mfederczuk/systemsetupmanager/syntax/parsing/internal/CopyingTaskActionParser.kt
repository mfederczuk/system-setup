/*
 * Copyright (c) 2025 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.syntax.parsing.internal

import io.github.mfederczuk.systemsetupmanager.syntax.cst.TaskAction
import io.github.mfederczuk.systemsetupmanager.syntax.parsing.internal.tokenparser.TokenParser
import io.github.mfederczuk.systemsetupmanager.syntax.parsing.internal.utils.iterator.BufferedIterator
import io.github.mfederczuk.systemsetupmanager.syntax.parsing.internal.utils.iterator.buffered
import io.github.mfederczuk.systemsetupmanager.syntax.parsing.internal.utils.iterator.nextOrNull
import io.github.mfederczuk.systemsetupmanager.syntax.token.Token
import kotlinx.collections.immutable.ImmutableList

internal val CopyingTaskActionParser: TokenParser<TaskAction.Copying> =
	TokenParser(Iterator<Token>::parseNextFileCopyingTaskAction)

private fun Iterator<Token>.parseNextFileCopyingTaskAction(): TaskAction.Copying? {
	val copyKeywordToken: Token.Keyword.Copy = this.startWithCopyKeyword() ?: return null

	val buffered: BufferedIterator<Token> = this.buffered()

	val innerTokens1: ImmutableList<Token.WhitespaceOrLineComment> = buffered.thenWhitespacesOrLineComments()
	val sourceToken: Token.StringLiteral = buffered.thenSource() ?: return null
	val innerTokens2: ImmutableList<Token.WhitespaceOrLineComment> = buffered.thenWhitespacesOrLineComments()
	val toKeywordToken: Token.Keyword.To = buffered.thenToKeyword() ?: return null
	val innerTokens3: ImmutableList<Token.WhitespaceOrLineComment> = buffered.thenWhitespacesOrLineComments()
	val targetToken: Token.StringLiteral = buffered.thenTarget() ?: return null

	return TaskAction.Copying(
		copyKeywordToken,
		innerTokens1,
		sourceToken,
		innerTokens2,
		toKeywordToken,
		innerTokens3,
		targetToken,
	)
}

private fun Iterator<Token>.startWithCopyKeyword(): Token.Keyword.Copy? {
	return this.nextOrNull() as? Token.Keyword.Copy
}

private fun Iterator<Token>.thenSource(): Token.StringLiteral? {
	val token: Token? = this.nextOrNull()

	if (token == null) {
		// TODO: report error
		return null
	}

	if (token !is Token.StringLiteral) {
		// TODO: report error
		return null
	}

	if (!(token.isTerminated)) {
		// TODO: report error
	}

	return token
}

private fun Iterator<Token>.thenToKeyword(): Token.Keyword.To? {
	val token: Token? = this.nextOrNull()

	if (token == null) {
		// TODO: report error
		return null
	}

	if (token !is Token.Keyword.To) {
		// TODO: report error
		return null
	}

	return token
}

private fun Iterator<Token>.thenTarget(): Token.StringLiteral? {
	val token: Token? = this.nextOrNull()

	if (token == null) {
		// TODO: report error
		return null
	}

	if (token !is Token.StringLiteral) {
		// TODO: report error
		return null
	}

	if (!(token.isTerminated)) {
		// TODO: report error
	}

	return token
}
