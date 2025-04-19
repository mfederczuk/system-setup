package io.github.mfederczuk.systemsetup.tasksrunner.actions

import java.nio.file.Path

data class FileExecAction(val filePath: Path) : DistroAgnosticTaskAction()
