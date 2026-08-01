package io.github.mfederczuk.systemsetupmanager.semantics.analyzes.internal

import io.github.mfederczuk.systemsetupmanager.semantics.ir.ImportString
import io.github.mfederczuk.systemsetupmanager.semantics.ir.ImportString.Companion.toImportStringOrNull
import io.github.mfederczuk.systemsetupmanager.syntax.ast.TasksModuleElement

internal fun TasksModuleElement.ImportStatement.semanticallyAnalyze(): ImportString? {
	// TODO: emit error if null
	return this.string.toImportStringOrNull()
}
