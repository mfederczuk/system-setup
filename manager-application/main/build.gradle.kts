// SPDX-License-Identifier: CC0-1.0

import java.io.InputStream
import java.io.OutputStream

plugins {
	application
	alias(libs.plugins.kotlinJvm)
	alias(libs.plugins.shadow)
}

dependencies {
	implementation(projects.syntax.lexing)
	implementation(projects.syntax.parsing)
	implementation(projects.semantics.analyzes)
	implementation(projects.semantics.ir)
}

application {
	mainClass = "io.github.mfederczuk.systemsetupmanager.Main"
}

val copyShadowJarToRootProjectDirectory: TaskProvider<out Task> =
	tasks.register<DefaultTask>(name = "copyShadowJarToRootProjectDirectory") {
		description = "Copies the Shadow JAR into the root project's project directory"

		inputs.file(tasks.shadowJar.map { it.outputs.files.singleFile })

		outputs.file(rootProject.layout.projectDirectory.file("${rootProject.name}.jar"))

		doFirst {
			val inputFile: File = inputs.files.singleFile
			val outputFile: File = outputs.files.singleFile

			outputFile.parentFile?.mkdirs()

			outputFile.outputStream().buffered().use { outputStream: OutputStream ->
				inputFile.inputStream().buffered().use { inputStream: InputStream ->
					inputStream.transferTo(outputStream)
				}
			}
		}
	}

tasks.assemble { dependsOn(copyShadowJarToRootProjectDirectory) }

tasks.clean { delete(copyShadowJarToRootProjectDirectory) }
