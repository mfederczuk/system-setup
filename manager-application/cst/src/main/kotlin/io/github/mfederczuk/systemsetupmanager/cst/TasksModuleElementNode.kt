/*
 * Copyright (c) 2025 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.cst

import io.github.mfederczuk.systemsetupmanager.token.Token
import kotlinx.collections.immutable.ImmutableList

public sealed class TasksModuleElementNode : Node() {

	public data class ImportStatement(
		private val importKeywordToken: Token.Keyword.Import,
		private val innerTokens: ImmutableList<Token.WhitespaceOrLineComment>,
		public val stringToken: Token.StringLiteral,
	) : TasksModuleElementNode() {

		override fun combineTokens(): ImmutableList<Token> {
			return buildImmutableList {
				add(importKeywordToken)
				addAll(innerTokens)
				add(stringToken)
			}
		}
	}

	public data class TaskDefinition(
		private val taskKeywordToken: Token.Keyword.Task,
		private val innerTokens1: ImmutableList<Token.WhitespaceOrLineComment>,
		public val nameToken: Token.Identifier,
		private val innerTokens2: ImmutableList<Token.WhitespaceOrLineComment>,
		private val openBraceToken: Token.Brace.Open,
		public val actions: EnclosedNodesList<TaskActionNode>,
		private val closedBraceToken: Token.Brace.Closed,
	) : TasksModuleElementNode() {

		override fun combineTokens(): ImmutableList<Token> {
			return buildImmutableList {
				add(taskKeywordToken)
				addAll(innerTokens1)
				add(nameToken)
				addAll(innerTokens2)
				add(openBraceToken)
				add(actions)
				add(closedBraceToken)
			}
		}
	}
}
