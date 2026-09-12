// SPDX-License-Identifier: CC0-1.0

plugins {
	`java-library`
	alias(libs.plugins.kotlinJvm)
}

dependencies {
	api(projects.sourcePosition)
	api(projects.syntax.ast)

	implementation(projects.syntax.patterns)
	implementation(projects.syntax.token)
	implementation(projects.syntax.cst)
}
