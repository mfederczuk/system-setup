package io.github.mfederczuk.systemsetupmanager.tasks

import io.github.mfederczuk.systemsetupmanager.tasks.actions.TaskAction
import kotlinx.collections.immutable.ImmutableList
import java.nio.file.Path

data class Task(
	val directoryPath: Path,
	val name: String,
	val actions: ImmutableList<TaskAction>,
)
