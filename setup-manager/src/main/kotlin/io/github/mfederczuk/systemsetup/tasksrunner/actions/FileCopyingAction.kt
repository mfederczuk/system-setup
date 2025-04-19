package io.github.mfederczuk.systemsetup.tasksrunner.actions

import io.github.mfederczuk.systemsetup.tasksrunner.DynamicPath
import java.nio.file.Path

data class FileCopyingAction(
	val sourceFilePath: Path,
	val targetFilePath: DynamicPath,
) : DistroAgnosticTaskAction()
