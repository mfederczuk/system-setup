/*
 * Copyright (c) 2025 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.parsing.internal

import io.github.mfederczuk.systemsetupmanager.cst.TaskActionNode.TaskExecution
import io.github.mfederczuk.systemsetupmanager.parsing.internal.tokenparser.TokenParser
import io.github.mfederczuk.systemsetupmanager.parsing.internal.utils.iterator.BufferedIterator
import io.github.mfederczuk.systemsetupmanager.parsing.internal.utils.iterator.buffered
import io.github.mfederczuk.systemsetupmanager.parsing.internal.utils.iterator.nextOrNull
import io.github.mfederczuk.systemsetupmanager.token.Token
import kotlinx.collections.immutable.ImmutableList

internal val TaskExecutionTaskActionParser: TokenParser<TaskExecution> =
	TokenParser(Iterator<Token>::parseNextTaskExecutionTaskAction)

private fun Iterator<Token>.parseNextTaskExecutionTaskAction(): TaskExecution? {
	val namespaceToken: Token.StringLiteral = this.startWithNamespace() ?: return null

	val buffered: BufferedIterator<Token> = this.buffered()

	val innerTokens1: ImmutableList<Token.WhitespaceOrLineComment> = buffered.thenWhitespacesOrLineComments()
	val doubleColonToken: Token.DoubleColon = buffered.thenDoubleColon() ?: return null
	val innerTokens2: ImmutableList<Token.WhitespaceOrLineComment> = buffered.thenWhitespacesOrLineComments()
	val taskNameToken: Token.Identifier = buffered.thenTaskName() ?: return null

	return TaskExecution(namespaceToken, innerTokens1, doubleColonToken, innerTokens2, taskNameToken)
}

private fun Iterator<Token>.startWithNamespace(): Token.StringLiteral? {
	val token: Token.StringLiteral = (this.nextOrNull() as? Token.StringLiteral) ?: return null

	if (!(token.isTerminated)) {
		// TODO: report error
	}

	return token
}

private fun Iterator<Token>.thenDoubleColon(): Token.DoubleColon? {
	val token: Token? = this.nextOrNull()

	if (token == null) {
		// TODO: report error
		return null
	}

	if (token !is Token.DoubleColon) {
		// TODO: report error
		return null
	}

	return token
}

private fun Iterator<Token>.thenTaskName(): Token.Identifier? {
	val token: Token? = this.nextOrNull()

	if (token == null) {
		// TODO: report error
		return null
	}

	if (token !is Token.Identifier) {
		// TODO: report error "unexpected token. expected an identifier, but got ..."
		return null
	}

	return token
}
