package io.github.mfederczuk.systemsetupmanager.tasks.actions

import io.github.mfederczuk.systemsetupmanager.TemplatedPath
import java.nio.file.Path

data class FileCopyingAction(
	val sourceFilePath: Path,
	val targetFilePath: TemplatedPath,
) : TaskAction()
