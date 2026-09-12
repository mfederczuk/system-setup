package io.github.mfederczuk.systemsetupmanager.semantics.analyzes

import io.github.mfederczuk.systemsetupmanager.syntax.ast.TasksModuleElement

public sealed interface SemanticProblem

public data class EmptyImportError(
	public val importStatement: TasksModuleElement.ImportStatement,
) : SemanticProblem

public data class OutOfPlaceImportError(
	public val importStatement: TasksModuleElement.ImportStatement,
) : SemanticProblem

public data class DuplicateImportWarning(
	public val importStatement: TasksModuleElement.ImportStatement,
) : SemanticProblem
