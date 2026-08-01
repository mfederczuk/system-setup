// SPDX-License-Identifier: CC0-1.0

plugins {
	`java-library`
	alias(libs.plugins.kotlinJvm)
}

dependencies {
	api(projects.syntax.patterns)
	api(libs.kotlinxImmutableCollections)

	implementation(projects.utils)
}
