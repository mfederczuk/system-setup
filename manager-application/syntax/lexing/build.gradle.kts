// SPDX-License-Identifier: CC0-1.0

plugins {
	`java-library`
	alias(libs.plugins.kotlinJvm)
}

dependencies {
	api(projects.syntax.token)

	implementation(projects.syntax.patterns)
}
