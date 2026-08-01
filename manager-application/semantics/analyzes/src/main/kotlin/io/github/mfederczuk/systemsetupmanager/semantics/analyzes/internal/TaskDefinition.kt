package io.github.mfederczuk.systemsetupmanager.semantics.analyzes.internal

import kotlinx.collections.immutable.ImmutableList
import kotlinx.collections.immutable.persistentListOf
import io.github.mfederczuk.systemsetupmanager.semantics.ir.TaskAction as TaskActionIr
import io.github.mfederczuk.systemsetupmanager.semantics.ir.TaskDefinition as TaskDefinitionIr
import io.github.mfederczuk.systemsetupmanager.syntax.ast.TaskAction as TaskActionAst
import io.github.mfederczuk.systemsetupmanager.syntax.ast.TasksModuleElement as TasksModuleAstElement

internal fun TasksModuleAstElement.TaskDefinition.semanticallyAnalyze(): TaskDefinitionIr {
	val actions: ImmutableList<TaskActionIr> = this.actions
		.mapNotNullTo(
			destination = persistentListOf<TaskActionIr>().builder(),
			transform = TaskActionAst::semanticallyAnalyze,
		)
		.build()

	return TaskDefinitionIr(this.identifier, actions)
}
