package io.github.mfederczuk.systemsetupmanager.actions

import kotlinx.collections.immutable.ImmutableList

data class DnfCoprRepositoriesEnablingAction(val repositories: ImmutableList<String>) : Fedora41TaskAction() {

	init {
		require(repositories.isNotEmpty())
	}
}

data class DnfPackagesInstallingAction(val packages: ImmutableList<String>) : Fedora41TaskAction() {

	init {
		require(packages.isNotEmpty())
	}
}
