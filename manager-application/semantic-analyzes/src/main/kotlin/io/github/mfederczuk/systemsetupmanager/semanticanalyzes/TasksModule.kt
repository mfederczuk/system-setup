/*
 * Copyright (c) 2025 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.semanticanalyzes

import io.github.mfederczuk.systemsetupmanager.ast.ImportString
import io.github.mfederczuk.systemsetupmanager.ast.TaskDefinition
import io.github.mfederczuk.systemsetupmanager.ast.TasksModule as TasksModuleAst
import io.github.mfederczuk.systemsetupmanager.cst.TasksModule as TasksModuleCst
import io.github.mfederczuk.systemsetupmanager.cst.TasksModuleElementNode
import io.github.mfederczuk.systemsetupmanager.semanticanalyzes.internal.semanticallyAnalyze
import kotlinx.collections.immutable.PersistentList
import kotlinx.collections.immutable.PersistentSet
import kotlinx.collections.immutable.persistentListOf
import kotlinx.collections.immutable.persistentSetOf

// TODO: add error/warning reporting

public fun TasksModuleCst.semanticallyAnalyze(): TasksModuleAst {
	val importStrings: PersistentSet.Builder<ImportString> = persistentSetOf<ImportString>().builder()
	val taskDefinitions: PersistentList.Builder<TaskDefinition> = persistentListOf<TaskDefinition>().builder()

	for (node: TasksModuleElementNode in this.elements.filterNodes()) {
		when (node) {
			is TasksModuleElementNode.ImportStatement -> {
				if (taskDefinitions.isNotEmpty()) {
					// TODO: report warning of import after (first) task definition
				}

				val importString: ImportString? = node.semanticallyAnalyze()

				if (importString != null) {
					val isUnique: Boolean = importStrings.add(importString)

					if (isUnique) {
						// TODO: report warning of duplicate import statement
					}
				}
			}

			is TasksModuleElementNode.TaskDefinition -> {
				val taskDefinition: TaskDefinition? = node.semanticallyAnalyze()

				if (taskDefinition != null) {
					taskDefinitions += taskDefinition
				}
			}
		}
	}

	return TasksModuleAst(
		importStrings = importStrings.build(),
		taskDefinitions = taskDefinitions.build(),
	)
}
