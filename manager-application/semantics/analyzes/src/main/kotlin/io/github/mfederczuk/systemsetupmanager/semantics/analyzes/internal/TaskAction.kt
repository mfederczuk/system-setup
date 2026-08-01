package io.github.mfederczuk.systemsetupmanager.semantics.analyzes.internal

import io.github.mfederczuk.systemsetupmanager.semantics.ir.TaskAction as TaskActionIr
import io.github.mfederczuk.systemsetupmanager.syntax.ast.TaskAction as TaskActionAst

internal fun TaskActionAst.semanticallyAnalyze(): TaskActionIr? {
	return when (this) {
		is TaskActionAst.Copying -> this.semanticallyAnalyze()
		is TaskActionAst.TaskExecution -> this.semanticallyAnalyze()
	}
}
