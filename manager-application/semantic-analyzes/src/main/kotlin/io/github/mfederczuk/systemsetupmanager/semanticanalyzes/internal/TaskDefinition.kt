package io.github.mfederczuk.systemsetupmanager.semanticanalyzes.internal

import io.github.mfederczuk.systemsetupmanager.ast.TaskAction
import io.github.mfederczuk.systemsetupmanager.ast.TaskDefinition
import io.github.mfederczuk.systemsetupmanager.ast.TaskName
import io.github.mfederczuk.systemsetupmanager.ast.TaskName.Companion.toTaskNameOrNull
import io.github.mfederczuk.systemsetupmanager.cst.TaskActionNode
import io.github.mfederczuk.systemsetupmanager.cst.TasksModuleElementNode
import kotlinx.collections.immutable.ImmutableList
import kotlinx.collections.immutable.persistentListOf

internal fun TasksModuleElementNode.TaskDefinition.semanticallyAnalyze(): TaskDefinition? {
	val name: TaskName = this.nameToken.identifierString.toTaskNameOrNull() ?: return null

	val actions: ImmutableList<TaskAction> = this.actions.filterNodes()
		.mapNotNullTo(
			destination = persistentListOf<TaskAction>().builder(),
			transform = TaskActionNode::semanticallyAnalyze,
		)
		.build()

	return TaskDefinition(name, actions)
}
