package io.github.mfederczuk.systemsetup.tasksrunner.actions

import kotlinx.collections.immutable.ImmutableList

data class TermuxPkgPackagesInstallingAction(val packages: ImmutableList<String>) : AndroidTermuxTaskAction() {

	init {
		require(packages.isNotEmpty())
	}
}
