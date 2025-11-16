/*
 * Copyright (c) 2025 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import org.jetbrains.kotlin.gradle.dsl.KotlinJvmProjectExtension

plugins {
	alias(libs.plugins.kotlinJvm) apply false
	alias(libs.plugins.shadow) apply false
}

val javaCompatibilityVersion = JavaVersion.VERSION_21

subprojects {
	val kotlinJvmPluginIdProvider: Provider<String> = rootProject.libs.plugins.kotlinJvm
		.map(PluginDependency::getPluginId)

	pluginManager.withPlugin("java-library") {
		extensions.configure<JavaPluginExtension>("java") {
			targetCompatibility = javaCompatibilityVersion
			sourceCompatibility = targetCompatibility
		}

		pluginManager.withPlugin(kotlinJvmPluginIdProvider.get()) {
			extensions.configure<KotlinJvmProjectExtension>("kotlin") {
				explicitApi()
			}
		}

		addJunitDependencies()
		useJunitPlatformForTests()
	}

	pluginManager.withPlugin("application") {
		extensions.configure<JavaPluginExtension>("java") {
			targetCompatibility = javaCompatibilityVersion
			sourceCompatibility = targetCompatibility
		}

		addJunitDependencies()
		useJunitPlatformForTests()
	}

	pluginManager.withPlugin(kotlinJvmPluginIdProvider.get()) {
		extensions.configure<KotlinJvmProjectExtension>("kotlin") {
			compilerOptions {
				jvmTarget = this@subprojects.provider {
					this@subprojects.extensions.getByName<JavaPluginExtension>("java")
						.targetCompatibility
						.toJvmTarget()
				}

				extraWarnings = true

				freeCompilerArgs.add("-Xreturn-value-checker=full")

				allWarningsAsErrors = findProperty("allWarningsAsErrors")
					?.toString()
					?.toBoolean()
			}
		}

		dependencies {
			add("testImplementation", kotlin("test"))
		}
	}
}

fun JavaVersion.toJvmTarget(): JvmTarget {
	return JvmTarget.fromTarget(this@toJvmTarget.toString())
}

fun Project.useJunitPlatformForTests() {
	tasks.named<Test>("test") {
		useJUnitPlatform()
	}
}

fun Project.addJunitDependencies() {
	dependencies {
		add("testImplementation", platform(rootProject.libs.junit.bom))
		add("testImplementation", rootProject.libs.junit.jupiter)
		add("testRuntimeOnly", rootProject.libs.junit.platformLauncher)
	}
}
