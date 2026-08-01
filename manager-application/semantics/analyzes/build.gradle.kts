// SPDX-License-Identifier: CC0-1.0

plugins {
	`java-library`
	alias(libs.plugins.kotlinJvm)
}

dependencies {
	api(projects.semantics.ir)

	implementation(projects.syntax.ast)
}
