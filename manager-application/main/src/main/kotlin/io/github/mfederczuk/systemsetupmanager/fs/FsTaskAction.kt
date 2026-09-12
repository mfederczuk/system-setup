package io.github.mfederczuk.systemsetupmanager.fs

import java.nio.file.Path

sealed class FsTaskAction {

	data class Copying(val sourcePath: Path, val targetPath: TemplatedPath) : FsTaskAction()

	data class TaskExecution(val namespace: String, val task: FsTaskDefinition) : FsTaskAction()
}
