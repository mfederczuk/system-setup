/*
 * Copyright (c) 2025 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.cst

import io.github.mfederczuk.systemsetupmanager.token.Token
import kotlinx.collections.immutable.ImmutableList

public sealed class TaskActionNode : Node() {

	public data class Copying(
		private val copyKeywordToken: Token.Keyword.Copy,
		private val innerTokens1: ImmutableList<Token.WhitespaceOrLineComment>,
		public val sourceToken: Token.StringLiteral,
		private val innerTokens2: ImmutableList<Token.WhitespaceOrLineComment>,
		private val toKeywordToken: Token.Keyword.To,
		private val innerTokens3: ImmutableList<Token.WhitespaceOrLineComment>,
		public val targetToken: Token.StringLiteral,
	) : TaskActionNode() {

		override fun combineTokens(): ImmutableList<Token> {
			return buildImmutableList {
				add(copyKeywordToken)
				addAll(innerTokens1)
				add(sourceToken)
				addAll(innerTokens2)
				add(toKeywordToken)
				addAll(innerTokens3)
				add(targetToken)
			}
		}
	}

	public data class TaskExecution(
		public val namespaceToken: Token.StringLiteral,
		private val innerTokens1: ImmutableList<Token.WhitespaceOrLineComment>,
		private val doubleColonToken: Token.DoubleColon,
		private val innerTokens2: ImmutableList<Token.WhitespaceOrLineComment>,
		public val taskNameToken: Token.Identifier,
	) : TaskActionNode() {

		override fun combineTokens(): ImmutableList<Token> {
			return buildImmutableList {
				add(namespaceToken)
				addAll(innerTokens1)
				add(doubleColonToken)
				addAll(innerTokens2)
				add(taskNameToken)
			}
		}
	}
}
