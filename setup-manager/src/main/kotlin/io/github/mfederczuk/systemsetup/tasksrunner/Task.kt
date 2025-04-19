package io.github.mfederczuk.systemsetup.tasksrunner

import io.github.mfederczuk.systemsetup.tasksrunner.actions.AndroidTermuxTaskAction
import io.github.mfederczuk.systemsetup.tasksrunner.actions.DistroAgnosticTaskAction
import io.github.mfederczuk.systemsetup.tasksrunner.actions.Fedora41TaskAction
import io.github.mfederczuk.systemsetup.tasksrunner.actions.TaskAction
import io.github.mfederczuk.systemsetup.tasksrunner.actions.Ubuntu2204TaskAction
import kotlinx.collections.immutable.ImmutableList

sealed class Task {

	abstract val name: String
	abstract val actions: ImmutableList<TaskAction>
}

data class DistroAgnosticTask(
	override val name: String,
	override val actions: ImmutableList<DistroAgnosticTaskAction>,
) : Task()

data class AndroidTermuxTask(
	override val name: String,
	override val actions: ImmutableList<AndroidTermuxTaskAction>,
) : Task()

data class Fedora41Task(
	override val name: String,
	override val actions: ImmutableList<Fedora41TaskAction>,
) : Task()

data class Ubuntu2204Task(
	override val name: String,
	override val actions: ImmutableList<Ubuntu2204TaskAction>,
) : Task()
