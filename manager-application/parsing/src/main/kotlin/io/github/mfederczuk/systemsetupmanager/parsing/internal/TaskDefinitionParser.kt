/*
 * Copyright (c) 2025 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.parsing.internal

import io.github.mfederczuk.systemsetupmanager.cst.EnclosedNodesList
import io.github.mfederczuk.systemsetupmanager.cst.TaskActionNode
import io.github.mfederczuk.systemsetupmanager.cst.TasksModuleElementNode.TaskDefinition
import io.github.mfederczuk.systemsetupmanager.parsing.internal.tokenparser.TokenParser
import io.github.mfederczuk.systemsetupmanager.parsing.internal.tokenparser.TokenParser.Companion.parseRemainingWith
import io.github.mfederczuk.systemsetupmanager.parsing.internal.utils.iterator.BufferedIterator
import io.github.mfederczuk.systemsetupmanager.parsing.internal.utils.iterator.buffered
import io.github.mfederczuk.systemsetupmanager.parsing.internal.utils.iterator.nextOrNull
import io.github.mfederczuk.systemsetupmanager.parsing.internal.utils.iterator.wrap
import io.github.mfederczuk.systemsetupmanager.token.Token
import kotlinx.collections.immutable.ImmutableList

internal val TaskDefinitionParser: TokenParser<TaskDefinition> =
	TokenParser(Iterator<Token>::parseNextTaskDefinition)

private fun Iterator<Token>.parseNextTaskDefinition(): TaskDefinition? {
	val taskKeywordToken: Token.Keyword.Task = this.startWithTaskKeyword() ?: return null

	val buffered: BufferedIterator<Token> = this.buffered()

	val innerTokens1: ImmutableList<Token.WhitespaceOrLineComment> = buffered.thenWhitespacesOrLineComments()
	val nameToken: Token.Identifier = buffered.thenTaskName() ?: return null
	val innerTokens2: ImmutableList<Token.WhitespaceOrLineComment> = buffered.thenWhitespacesOrLineComments()
	val openBraceToken: Token.Brace.Open = buffered.thenOpenBrace() ?: return null
	val actions: EnclosedNodesList<TaskActionNode> =
		wrap(buffered, until = { it is Token.Brace.Closed }) { bodyTokens: Iterator<Token> ->
			bodyTokens.parseRemainingWith(TaskActionParser)
		}
	val closedBraceToken: Token.Brace.Closed = buffered.thenClosedBrace() ?: return null

	return TaskDefinition(
		taskKeywordToken,
		innerTokens1,
		nameToken,
		innerTokens2,
		openBraceToken,
		actions,
		closedBraceToken,
	)
}

private fun Iterator<Token>.startWithTaskKeyword(): Token.Keyword.Task? {
	return this.nextOrNull() as? Token.Keyword.Task
}

private fun Iterator<Token>.thenTaskName(): Token.Identifier? {
	val token: Token? = this.nextOrNull()

	if (token == null) {
		// TODO: report error
		return null
	}

	if (token !is Token.Identifier) {
		// TODO: report error
		return null
	}

	return token
}

private fun Iterator<Token>.thenOpenBrace(): Token.Brace.Open? {
	val token: Token? = this.nextOrNull()

	if (token == null) {
		// TODO: report error
		return null
	}

	if (token !is Token.Brace.Open) {
		// TODO: report error
		return null
	}

	return token
}

private fun Iterator<Token>.thenClosedBrace(): Token.Brace.Closed? {
	val token: Token? = this.nextOrNull()

	if (token == null) {
		// TODO: report error
		return null
	}

	if (token !is Token.Brace.Closed) {
		// TODO: report error
		return null
	}

	return token
}
