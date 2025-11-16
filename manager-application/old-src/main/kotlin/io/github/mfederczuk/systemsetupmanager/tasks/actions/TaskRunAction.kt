package io.github.mfederczuk.systemsetupmanager.tasks.actions

import io.github.mfederczuk.systemsetupmanager.tasks.TaskName
import java.nio.file.Path

data class TaskRunAction(
	val directoryPath: Path,
	val taskName: TaskName,
) : TaskAction()
