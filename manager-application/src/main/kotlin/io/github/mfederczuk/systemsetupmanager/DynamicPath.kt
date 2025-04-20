package io.github.mfederczuk.systemsetupmanager

import java.nio.file.Path

enum class DynamicPathRootComponent {
	Home,
	XdgConfigHome,
}

// TODO: this needs a better name
data class DynamicPath(
	val rootComponent: DynamicPathRootComponent,
	val relativePath: Path,
) {

	init {
		require(!(relativePath.isAbsolute))
	}

	fun resolve(userHome: Path, xdgConfigHome: Path): Path {
		val rootPath: Path =
			when (this.rootComponent) {
				DynamicPathRootComponent.Home -> userHome
				DynamicPathRootComponent.XdgConfigHome -> xdgConfigHome
			}

		return rootPath.resolve(this.relativePath)
	}
}
