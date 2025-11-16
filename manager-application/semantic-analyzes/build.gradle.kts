// SPDX-License-Identifier: CC0-1.0

plugins {
	`java-library`
	alias(libs.plugins.kotlinJvm)
}

dependencies {
	implementation(projects.cst)
	api(projects.ast)
}
