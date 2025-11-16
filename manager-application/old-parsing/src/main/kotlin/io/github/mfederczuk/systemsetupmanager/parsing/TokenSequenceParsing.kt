/*
 * Copyright (c) 2025 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.parsing.old

import io.github.mfederczuk.systemsetupmanager.ast.ImportString
import io.github.mfederczuk.systemsetupmanager.ast.TaskDefinition
import io.github.mfederczuk.systemsetupmanager.ast.TasksModule
import io.github.mfederczuk.systemsetupmanager.parsing.old.internal.TasksUnitElement
import io.github.mfederczuk.systemsetupmanager.parsing.old.internal.parseToTasksUnitElements
import io.github.mfederczuk.systemsetupmanager.parsing.old.issues.ParsingPhaseIssue.Companion.at
import io.github.mfederczuk.systemsetupmanager.parsing.old.issues.ParsingPhaseIssueReporter
import io.github.mfederczuk.systemsetupmanager.parsing.old.issues.StaticSemanticWarningType.DuplicateImport
import io.github.mfederczuk.systemsetupmanager.parsing.old.issues.StaticSemanticWarningType.ImportStatementAfterTaskDefinition
import io.github.mfederczuk.systemsetupmanager.token.Token
import kotlinx.collections.immutable.toImmutableList
import kotlinx.collections.immutable.toImmutableSet

public fun Sequence<Token>.parse(issueReporter: ParsingPhaseIssueReporter): TasksModule {
	val importStrings: MutableSet<ImportString> = mutableSetOf()
	val taskDefinitions: MutableList<TaskDefinition> = mutableListOf()

	for (element: TasksUnitElement in this.parseToTasksUnitElements(issueReporter)) {
		when (element) {
			is TasksUnitElement.ImportStatement -> {
				if (taskDefinitions.isNotEmpty()) {
					issueReporter.report(ImportStatementAfterTaskDefinition at element.sourceRange)
				}

				val added: Boolean = importStrings.add(element.importString)
				if (!added) {
					issueReporter.report(DuplicateImport at element.sourceRange)
				}
			}

			is TasksUnitElement.TaskDefinition -> {
				taskDefinitions += element.taskDefinition
			}
		}
	}

	return TasksModule(
		importStrings = importStrings.toImmutableSet(),
		taskDefinitions = taskDefinitions.toImmutableList(),
	)
}
