package io.github.mfederczuk.systemsetupmanager.actions

import kotlinx.collections.immutable.ImmutableList

data class TermuxPkgPackagesInstallingAction(val packages: ImmutableList<String>) : AndroidTermuxTaskAction() {

	init {
		require(packages.isNotEmpty())
	}
}
