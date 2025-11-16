package io.github.mfederczuk.systemsetupmanager.semanticanalyzes.internal

import io.github.mfederczuk.systemsetupmanager.ast.TaskAction
import io.github.mfederczuk.systemsetupmanager.cst.TaskActionNode

internal fun TaskActionNode.semanticallyAnalyze(): TaskAction? {
	return when (this) {
		is TaskActionNode.Copying -> this.semanticallyAnalyze()
		is TaskActionNode.TaskExecution -> this.semanticallyAnalyze()
	}
}
