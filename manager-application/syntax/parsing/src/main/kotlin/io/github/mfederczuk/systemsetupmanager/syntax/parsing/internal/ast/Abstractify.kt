/*
 * Copyright (c) 2026 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.syntax.parsing.internal.ast

import io.github.mfederczuk.systemsetupmanager.syntax.parsing.IllegalTaskIdentifierProblem
import io.github.mfederczuk.systemsetupmanager.syntax.parsing.IllegalTaskIdentifierProblem.Companion.determineIllegalTaskIdentifierProblems
import io.github.mfederczuk.systemsetupmanager.syntax.patterns.Identifier
import kotlinx.collections.immutable.ImmutableSet
import kotlinx.collections.immutable.toImmutableList
import io.github.mfederczuk.systemsetupmanager.syntax.ast.TaskAction as AstTaskAction
import io.github.mfederczuk.systemsetupmanager.syntax.ast.TasksModule as AstTasksModule
import io.github.mfederczuk.systemsetupmanager.syntax.ast.TasksModuleElement as AstTasksModuleElement
import io.github.mfederczuk.systemsetupmanager.syntax.cst.TaskAction as CstTaskAction
import io.github.mfederczuk.systemsetupmanager.syntax.cst.TasksModule as CstTasksModule
import io.github.mfederczuk.systemsetupmanager.syntax.cst.TasksModuleElement as CstTasksModuleElement

internal fun CstTasksModule.abstractify(): AstTasksModule {
	return AstTasksModule(
		elements = this.elements
			.filterNodes()
			.map(CstTasksModuleElement::abstractify)
			.toImmutableList(),
	)
}

private fun CstTasksModuleElement.abstractify(): AstTasksModuleElement {
	return when (this) {
		is CstTasksModuleElement.ImportStatement -> {
			AstTasksModuleElement.ImportStatement(string = this.stringToken.contents)
		}

		is CstTasksModuleElement.TaskDefinition -> {
			AstTasksModuleElement.TaskDefinition(
				identifier = this.identifierToken.unwrapped,
				actions = this.actions
					.filterNodes()
					.map(CstTaskAction::abstractify)
					.toImmutableList(),
			)
		}
	}
}

private fun CstTaskAction.abstractify(): AstTaskAction {
	return when (this) {
		is CstTaskAction.Copying -> {
			AstTaskAction.Copying(
				source = this.sourceToken.contents,
				target = this.targetToken.contents,
			)
		}

		is CstTaskAction.TaskExecution -> {
			val taskIdentifier: Identifier = this.taskIdentifierToken.unwrapped

			val illegalTaskIdentifierProblems: ImmutableSet<IllegalTaskIdentifierProblem> =
				taskIdentifier.determineIllegalTaskIdentifierProblems()
			if (illegalTaskIdentifierProblems.isNotEmpty()) {
				// TODO: report error
			}

			AstTaskAction.TaskExecution(
				namespace = this.namespaceToken.contents,
				taskIdentifier = taskIdentifier,
			)
		}
	}
}
