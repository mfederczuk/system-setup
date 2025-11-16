package io.github.mfederczuk.systemsetupmanager.semanticanalyzes.internal

import io.github.mfederczuk.systemsetupmanager.ast.ImportString
import io.github.mfederczuk.systemsetupmanager.ast.ImportString.Companion.toImportStringOrNull
import io.github.mfederczuk.systemsetupmanager.ast.TaskAction
import io.github.mfederczuk.systemsetupmanager.ast.TaskName
import io.github.mfederczuk.systemsetupmanager.ast.TaskName.Companion.toTaskNameOrNull
import io.github.mfederczuk.systemsetupmanager.cst.TaskActionNode

internal fun TaskActionNode.TaskExecution.semanticallyAnalyze(): TaskAction.TaskExecution? {
	val namespace: ImportString = this.namespaceToken.contents.toImportStringOrNull() ?: return null

	val taskName: TaskName = this.taskNameToken.identifierString.toTaskNameOrNull() ?: return null

	return TaskAction.TaskExecution(namespace, taskName)
}
