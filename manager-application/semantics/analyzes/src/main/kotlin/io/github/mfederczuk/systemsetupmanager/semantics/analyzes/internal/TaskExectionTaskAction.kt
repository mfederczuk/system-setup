package io.github.mfederczuk.systemsetupmanager.semantics.analyzes.internal

import io.github.mfederczuk.systemsetupmanager.semantics.ir.ImportString
import io.github.mfederczuk.systemsetupmanager.semantics.ir.ImportString.Companion.toImportStringOrNull
import io.github.mfederczuk.systemsetupmanager.semantics.ir.TaskAction as TaskActionIr
import io.github.mfederczuk.systemsetupmanager.syntax.ast.TaskAction as TaskActionAst

internal fun TaskActionAst.TaskExecution.semanticallyAnalyze(): TaskActionIr.TaskExecution? {
	// TODO: emit error if null
	val namespace: ImportString = this.namespace.toImportStringOrNull() ?: return null

	return TaskActionIr.TaskExecution(namespace, this.taskIdentifier)
}
