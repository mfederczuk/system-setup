/*
 * Copyright (c) 2026 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.syntax.cst

import io.github.mfederczuk.systemsetupmanager.syntax.token.Token
import kotlinx.collections.immutable.ImmutableList
import kotlinx.collections.immutable.persistentListOf
import kotlinx.collections.immutable.plus

public sealed class TaskAction : Node() {

	public data class Copying(
		private val copyKeywordToken: Token.Keyword.Copy,
		private val innerTokens1: ImmutableList<Token.WhitespaceOrLineComment>,
		public val sourceToken: Token.StringLiteral,
		private val innerTokens2: ImmutableList<Token.WhitespaceOrLineComment>,
		private val toKeywordToken: Token.Keyword.To,
		private val innerTokens3: ImmutableList<Token.WhitespaceOrLineComment>,
		public val targetToken: Token.StringLiteral,
	) : TaskAction() {

		override fun combineTokens(): ImmutableList<Token> {
			return persistentListOf(this.copyKeywordToken) +
				this.innerTokens1 +
				this.sourceToken +
				this.innerTokens2 +
				this.toKeywordToken +
				this.innerTokens3 +
				this.targetToken
		}
	}

	public data class TaskExecution(
		public val namespaceToken: Token.StringLiteral,
		private val innerTokens1: ImmutableList<Token.WhitespaceOrLineComment>,
		private val doubleColonToken: Token.DoubleColon,
		private val innerTokens2: ImmutableList<Token.WhitespaceOrLineComment>,
		public val taskIdentifierToken: Token.Identifier,
	) : TaskAction() {

		override fun combineTokens(): ImmutableList<Token> {
			return persistentListOf(this.namespaceToken) +
				this.innerTokens1 +
				this.doubleColonToken +
				this.innerTokens2 +
				this.taskIdentifierToken
		}
	}
}
