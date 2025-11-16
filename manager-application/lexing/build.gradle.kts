// SPDX-License-Identifier: CC0-1.0

plugins {
	`java-library`
	alias(libs.plugins.kotlinJvm)
}

kotlin {
	compilerOptions {
		freeCompilerArgs.add("-Xcontext-parameters")
	}
}

dependencies {
	api(projects.token)
}
