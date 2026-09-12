/*
 * Copyright (c) 2026 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.syntax.parsing.internal.ast

import io.github.mfederczuk.systemsetupmanager.sourceposition.SourcePosition
import io.github.mfederczuk.systemsetupmanager.sourceposition.SourcePosition.Companion.sourcePositionRange
import io.github.mfederczuk.systemsetupmanager.sourceposition.SourcePositionRange
import io.github.mfederczuk.systemsetupmanager.syntax.parsing.IllegalTaskIdentifierError
import io.github.mfederczuk.systemsetupmanager.syntax.parsing.ParsingProblemReporter
import io.github.mfederczuk.systemsetupmanager.syntax.parsing.TaskIdentifierProblemType
import io.github.mfederczuk.systemsetupmanager.syntax.parsing.TaskIdentifierProblemType.Companion.determineTaskIdentifierProblems
import io.github.mfederczuk.systemsetupmanager.syntax.patterns.Identifier
import io.github.mfederczuk.systemsetupmanager.syntax.token.Token
import kotlinx.collections.immutable.ImmutableSet
import kotlinx.collections.immutable.toImmutableList
import io.github.mfederczuk.systemsetupmanager.syntax.ast.TaskAction as AstTaskAction
import io.github.mfederczuk.systemsetupmanager.syntax.ast.TasksModule as AstTasksModule
import io.github.mfederczuk.systemsetupmanager.syntax.ast.TasksModuleElement as AstTasksModuleElement
import io.github.mfederczuk.systemsetupmanager.syntax.cst.TaskAction as CstTaskAction
import io.github.mfederczuk.systemsetupmanager.syntax.cst.TasksModule as CstTasksModule
import io.github.mfederczuk.systemsetupmanager.syntax.cst.TasksModuleElement as CstTasksModuleElement

internal fun CstTasksModule.abstractify(problemReporter: ParsingProblemReporter): AstTasksModule {
	return AstTasksModule(
		elements = this.elements
			.filterNodesWithPosition()
			.map { (position: SourcePosition, element: CstTasksModuleElement) ->
				element.abstractify(position, problemReporter)
			}
			.toImmutableList(),
	)
}

private fun CstTasksModuleElement.abstractify(
	position: SourcePosition,
	problemReporter: ParsingProblemReporter,
): AstTasksModuleElement {
	val sourcePositionRange: SourcePositionRange = this.toSourceCode().sourcePositionRange(start = position)

	return when (this) {
		is CstTasksModuleElement.ImportStatement -> {
			AstTasksModuleElement.ImportStatement(
				sourcePositionRange = sourcePositionRange,
				string = this.stringToken.contents,
			)
		}

		is CstTasksModuleElement.TaskDefinition -> {
			AstTasksModuleElement.TaskDefinition(
				sourcePositionRange = sourcePositionRange,
				identifier = this.identifierToken.unwrapped,
				actions = this.actions
					.filterNodesWithPosition(begin = position)
					.map { (position: SourcePosition, action: CstTaskAction) ->
						action.abstractify(position, problemReporter)
					}
					.toImmutableList(),
			)
		}
	}
}

private fun CstTaskAction.abstractify(
	position: SourcePosition,
	problemReporter: ParsingProblemReporter,
): AstTaskAction {
	val sourcePositionRange: SourcePositionRange = this.toSourceCode().sourcePositionRange(start = position)

	return when (this) {
		is CstTaskAction.Copying -> {
			AstTaskAction.Copying(
				sourcePositionRange = sourcePositionRange,
				source = this.sourceToken.contents,
				target = this.targetToken.contents,
			)
		}

		is CstTaskAction.TaskExecution -> {
			val taskIdentifier: Identifier = this.taskIdentifierToken.unwrapped

			val taskIdentifierProblemTypes: ImmutableSet<TaskIdentifierProblemType> =
				taskIdentifier.determineTaskIdentifierProblems()
			if (taskIdentifierProblemTypes.isNotEmpty()) {
				val error =
					IllegalTaskIdentifierError(
						sourcePosition = this.combineTokens()
							.takeWhile { token: Token ->
								token != this.taskIdentifierToken
							}
							.fold(initial = position) { acc: SourcePosition, token: Token ->
								acc + token.toSourceCode()
							},
						token = this.taskIdentifierToken,
						problemTypes = taskIdentifierProblemTypes,
					)

				problemReporter.reportProblem(error)
			}

			AstTaskAction.TaskExecution(
				sourcePositionRange = sourcePositionRange,
				namespace = this.namespaceToken.contents,
				taskIdentifier = taskIdentifier,
			)
		}
	}
}
