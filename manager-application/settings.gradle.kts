// SPDX-License-Identifier: CC0-1.0

rootProject.name = "system-setup-manager"

pluginManagement {
	repositories {
		gradlePluginPortal()
	}
}

dependencyResolutionManagement {
	repositoriesMode = RepositoriesMode.FAIL_ON_PROJECT_REPOS
	repositories {
		mavenCentral()
	}
}

enableFeaturePreview("TYPESAFE_PROJECT_ACCESSORS")

include(
	":source-position",

	":token",
	":lexing",

	":cst",
	":parsing",

	":ast",
	":semantic-analyzes",

	":main",
)
