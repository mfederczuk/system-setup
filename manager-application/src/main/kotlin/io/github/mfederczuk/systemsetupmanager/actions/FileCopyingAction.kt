package io.github.mfederczuk.systemsetupmanager.actions

import io.github.mfederczuk.systemsetupmanager.DynamicPath
import java.nio.file.Path

data class FileCopyingAction(
	val sourceFilePath: Path,
	val targetFilePath: DynamicPath,
) : DistroAgnosticTaskAction()
