package io.github.mfederczuk.systemsetupmanager.semantics.analyzes.internal

import io.github.mfederczuk.systemsetupmanager.semantics.ir.TaskAction as TaskActionIr
import io.github.mfederczuk.systemsetupmanager.syntax.ast.TaskAction as TaskActionAst

internal fun TaskActionAst.Copying.semanticallyAnalyze(): TaskActionIr.Copying? {
	// TODO: emit errors if either are empty
	val source: String = this.source.takeIf(String::isNotEmpty) ?: return null
	val target: String = this.target.takeIf(String::isNotEmpty) ?: return null

	return TaskActionIr.Copying(source, target)
}
