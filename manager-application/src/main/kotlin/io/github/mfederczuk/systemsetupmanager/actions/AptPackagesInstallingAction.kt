package io.github.mfederczuk.systemsetupmanager.actions

import kotlinx.collections.immutable.ImmutableList

data class AptPackagesInstallingAction(val packages: ImmutableList<String>) : Ubuntu2204TaskAction() {

	init {
		require(packages.isNotEmpty())
	}
}
