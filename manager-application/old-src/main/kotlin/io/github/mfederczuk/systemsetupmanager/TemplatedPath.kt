package io.github.mfederczuk.systemsetupmanager

import java.nio.file.Path

enum class DynamicPathRootComponent {
	HOME,
	XDG_CONFIG_HOME,
}

data class TemplatedPath(
	val rootComponent: DynamicPathRootComponent,
	val relativePath: Path,
) {

	init {
		require(!(relativePath.isAbsolute))
	}

	fun resolve(userHome: Path, xdgConfigHome: Path): Path {
		val rootPath: Path =
			when (this.rootComponent) {
				DynamicPathRootComponent.HOME -> userHome
				DynamicPathRootComponent.XDG_CONFIG_HOME -> xdgConfigHome
			}

		return rootPath.resolve(this.relativePath)
	}
}
