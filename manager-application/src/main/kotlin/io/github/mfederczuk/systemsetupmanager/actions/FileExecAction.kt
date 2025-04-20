package io.github.mfederczuk.systemsetupmanager.actions

import java.nio.file.Path

data class FileExecAction(val filePath: Path) : DistroAgnosticTaskAction()
