package io.github.mfederczuk.systemsetupmanager.semanticanalyzes.internal

import io.github.mfederczuk.systemsetupmanager.ast.TaskAction
import io.github.mfederczuk.systemsetupmanager.cst.TaskActionNode

internal fun TaskActionNode.Copying.semanticallyAnalyze(): TaskAction.Copying? {
	val source: String = this.sourceToken.contents.takeIf(String::isNotEmpty) ?: return null
	val target: String = this.targetToken.contents.takeIf(String::isNotEmpty) ?: return null

	return TaskAction.Copying(source, target)
}
