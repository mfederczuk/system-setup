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

@Suppress("ktlint:standard:no-blank-line-in-list")
include(
	":utils",

	":source-position",

	":syntax:patterns",

	":syntax:token",
	":syntax:lexing",

	":syntax:cst",
	":syntax:ast",
	":syntax:parsing",

	":semantics:ir",
	":semantics:analyzes",

	":main",
)
