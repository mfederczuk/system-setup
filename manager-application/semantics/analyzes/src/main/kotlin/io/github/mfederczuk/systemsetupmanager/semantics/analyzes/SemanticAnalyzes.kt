/*
 * Copyright (c) 2026 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.semantics.analyzes

import io.github.mfederczuk.systemsetupmanager.semantics.analyzes.internal.semanticallyAnalyze
import io.github.mfederczuk.systemsetupmanager.semantics.ir.ImportString
import io.github.mfederczuk.systemsetupmanager.syntax.ast.TasksModuleElement
import kotlinx.collections.immutable.ImmutableList
import kotlinx.collections.immutable.PersistentList
import kotlinx.collections.immutable.PersistentMap
import kotlinx.collections.immutable.persistentListOf
import kotlinx.collections.immutable.persistentMapOf
import kotlinx.collections.immutable.plus
import io.github.mfederczuk.systemsetupmanager.semantics.ir.TaskDefinition as TaskDefinitionIr
import io.github.mfederczuk.systemsetupmanager.semantics.ir.TasksModule as TasksModuleIr
import io.github.mfederczuk.systemsetupmanager.syntax.ast.TasksModule as TasksModuleAst

// TODO: add error/warning reporting

@FunctionalInterface
public fun interface ModuleImporter {

	// TODO: returns either `TasksModuleAst` or an error
	public fun importModule(parentImports: ImmutableList<ImportString>, string: ImportString): TasksModuleAst
}

public fun TasksModuleAst.semanticallyAnalyze(moduleImporter: ModuleImporter): TasksModuleIr {
	return this.semanticallyAnalyze(
		parentImports = persistentListOf(),
		moduleImporter = moduleImporter,
	)
}

private fun TasksModuleAst.semanticallyAnalyze(
	parentImports: PersistentList<ImportString>,
	moduleImporter: ModuleImporter,
): TasksModuleIr {
	val importedModules: PersistentMap.Builder<ImportString, TasksModuleIr> =
		persistentMapOf<ImportString, TasksModuleIr>().builder()
	val taskDefinitions: PersistentList.Builder<TaskDefinitionIr> = persistentListOf<TaskDefinitionIr>().builder()

	// TODO: check namespaces that are not imported
	// TODO: how exactly should invalid things be handled? still keep them in the IR but with an `invalid` value?
	for (element: TasksModuleElement in this.elements) {
		when (element) {
			is TasksModuleElement.ImportStatement -> {
				foo(
					parentImports = parentImports,
					moduleImporter = moduleImporter,
					importedModules = importedModules,
					taskDefinitions = taskDefinitions,
					importStatement = element,
				)
			}

			is TasksModuleElement.TaskDefinition -> taskDefinitions += element.semanticallyAnalyze()
		}
	}

	return TasksModuleIr(
		importedModules = importedModules.build(),
		taskDefinitions = taskDefinitions.build(),
	)
}

// TODO: name
@Suppress("NOTHING_TO_INLINE")
private inline fun foo(
	parentImports: PersistentList<ImportString>,
	moduleImporter: ModuleImporter,
	importedModules: MutableMap<ImportString, TasksModuleIr>,
	taskDefinitions: MutableList<TaskDefinitionIr>,
	importStatement: TasksModuleElement.ImportStatement,
) {
	if (taskDefinitions.isNotEmpty()) {
		// TODO: report warning of import after (first) task definition
	}

	val importString: ImportString = importStatement.semanticallyAnalyze()
		?: return // TODO: report error

	if (importString in importedModules.keys) {
		// TODO: report warning of duplicate import statement
		return
	}

	importedModules[importString] = moduleImporter
		.importModule(
			parentImports = parentImports,
			string = importString,
		)
		.semanticallyAnalyze(
			parentImports = parentImports + importString,
			moduleImporter = moduleImporter,
		)
}
