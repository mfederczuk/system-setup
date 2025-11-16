package io.github.mfederczuk.systemsetupmanager.semanticanalyzes.internal

import io.github.mfederczuk.systemsetupmanager.ast.ImportString
import io.github.mfederczuk.systemsetupmanager.ast.ImportString.Companion.toImportStringOrNull
import io.github.mfederczuk.systemsetupmanager.cst.TasksModuleElementNode

internal fun TasksModuleElementNode.ImportStatement.semanticallyAnalyze(): ImportString? {
	return this.stringToken.contents.toImportStringOrNull()
}
