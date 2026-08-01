/*
 * Copyright (c) 2026 Michael Federczuk
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
		java {
			targetCompatibility = javaCompatibilityVersion
			sourceCompatibility = targetCompatibility
		}

		pluginManager.withPlugin(kotlinJvmPluginIdProvider.get()) {
			kotlin {
				explicitApi()
			}
		}

		addJunitDependencies()
		useJunitPlatformForTests()
	}

	pluginManager.withPlugin("application") {
		java {
			targetCompatibility = javaCompatibilityVersion
			sourceCompatibility = targetCompatibility
		}

		addJunitDependencies()
		useJunitPlatformForTests()
	}

	pluginManager.withPlugin(kotlinJvmPluginIdProvider.get()) {
		kotlin {
			compilerOptions {
				jvmTarget =
					this@subprojects.provider {
						this@subprojects.extensions.getByName<JavaPluginExtension>("java")
							.targetCompatibility
							.toJvmTarget()
					}

				extraWarnings = true
				allWarningsAsErrors = findProperty("allWarningsAsErrors")?.toString()?.toBoolean()

				// <https://github.com/Kotlin/KEEP/blob/main/proposals/KEEP-0412-unused-return-value-checker.md>
				freeCompilerArgs.add("-Xreturn-value-checker=full")
			}
		}

		dependencies {
			add("testImplementation", kotlin("test"))
		}
	}
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

fun Project.java(configure: JavaPluginExtension.() -> Unit) {
	this.extensions.configure("java", configure)
}

fun Project.kotlin(configure: KotlinJvmProjectExtension.() -> Unit) {
	this.extensions.configure("kotlin", configure)
}

fun JavaVersion.toJvmTarget(): JvmTarget {
	return JvmTarget.fromTarget(this.toString())
}
