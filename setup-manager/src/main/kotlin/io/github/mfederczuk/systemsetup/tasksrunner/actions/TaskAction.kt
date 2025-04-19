package io.github.mfederczuk.systemsetup.tasksrunner.actions

sealed class TaskAction

sealed class DistroAgnosticTaskAction : TaskAction()

sealed class Fedora41TaskAction : TaskAction()
sealed class Ubuntu2204TaskAction : TaskAction()
sealed class AndroidTermuxTaskAction : TaskAction()
