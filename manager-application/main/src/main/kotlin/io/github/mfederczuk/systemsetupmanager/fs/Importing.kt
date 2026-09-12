/*
 * Copyright (c) 2026 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.fs

import io.github.mfederczuk.systemsetupmanager.semantics.analyzes.semanticallyAnalyze
import io.github.mfederczuk.systemsetupmanager.semantics.ir.ImportString
import io.github.mfederczuk.systemsetupmanager.syntax.lexing.tokenize
import io.github.mfederczuk.systemsetupmanager.syntax.parsing.parse
import kotlinx.collections.immutable.ImmutableList
import java.io.Reader
import java.nio.file.Path
import kotlin.io.path.bufferedReader
import kotlin.io.path.div
import io.github.mfederczuk.systemsetupmanager.semantics.ir.TasksModule as TasksModuleIr
import io.github.mfederczuk.systemsetupmanager.syntax.ast.TasksModule as TasksModuleAst

private const val TASKS_MODULE_FILE_NAME: String = "Tasks"

fun loadTasksModuleFrom(moduleDirectory: Path): TasksModuleIr {
	return loadTasksModuleAstFrom(moduleDirectory)
		.semanticallyAnalyze { parentImports: ImmutableList<ImportString>, string: ImportString ->
			val importedModuleDirectory: Path = (parentImports + string)
				.fold(initial = moduleDirectory, operation = Path::div)

			loadTasksModuleAstFrom(importedModuleDirectory)
		}
}

private fun loadTasksModuleAstFrom(moduleDirectory: Path): TasksModuleAst {
	val moduleFilePath: Path = moduleDirectory / TASKS_MODULE_FILE_NAME

	return try {
		moduleFilePath.bufferedReader()
	} catch (_: NoSuchFileException) {
		error("Directory \"$moduleDirectory\" is not a tasks module (no such file \"Tasks\")")
	}.use { moduleFileReader: Reader ->
		moduleFileReader.tokenize().parse()
	}
}

private operator fun Path.div(importString: ImportString): Path {
	return this / importString.value
}
