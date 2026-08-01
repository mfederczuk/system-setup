/*
 * Copyright (c) 2026 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.syntax.cst

import io.github.mfederczuk.systemsetupmanager.syntax.token.Token
import kotlinx.collections.immutable.ImmutableList
import kotlinx.collections.immutable.persistentListOf
import kotlinx.collections.immutable.plus

public sealed class TasksModuleElement : Node() {

	public data class ImportStatement(
		private val importKeywordToken: Token.Keyword.Import,
		private val innerTokens: ImmutableList<Token.WhitespaceOrLineComment>,
		public val stringToken: Token.StringLiteral,
	) : TasksModuleElement() {

		override fun combineTokens(): ImmutableList<Token> {
			return persistentListOf(this.importKeywordToken) +
				this.innerTokens +
				this.stringToken
		}
	}

	public data class TaskDefinition(
		private val taskKeywordToken: Token.Keyword.Task,
		private val innerTokens1: ImmutableList<Token.WhitespaceOrLineComment>,
		public val identifierToken: Token.Identifier,
		private val innerTokens2: ImmutableList<Token.WhitespaceOrLineComment>,
		private val openBraceToken: Token.Brace.Open,
		public val actions: EnclosedNodesList<TaskAction>,
		private val closedBraceToken: Token.Brace.Closed,
	) : TasksModuleElement() {

		override fun combineTokens(): ImmutableList<Token> {
			return persistentListOf(this.taskKeywordToken) +
				this.innerTokens1 +
				this.identifierToken +
				this.innerTokens2 +
				this.openBraceToken +
				this.actions.combineTokens() +
				this.closedBraceToken
		}
	}
}
