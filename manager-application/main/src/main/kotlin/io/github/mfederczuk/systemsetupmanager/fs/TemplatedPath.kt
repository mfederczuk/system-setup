package io.github.mfederczuk.systemsetupmanager.fs

import java.nio.file.Path
import kotlin.io.path.div

data class TemplatedPath(
	val root: Root,
	val relativePath: Path,
) {

	enum class Root {
		UserHome,
		ConfigHome,
	}

	init {
		require(!(relativePath.isAbsolute))
	}

	override fun toString(): String {
		return "<${this.root}>/${this.relativePath}"
	}

	fun resolve(userHome: Path, configHome: Path): Path {
		val rootPath: Path =
			when (this.root) {
				Root.UserHome -> userHome
				Root.ConfigHome -> configHome
			}

		return rootPath / this.relativePath
	}
}
