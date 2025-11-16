import java.io.InputStream
import java.io.OutputStream

// SPDX-License-Identifier: CC0-1.0

plugins {
	application
	alias(libs.plugins.kotlinJvm)
	alias(libs.plugins.shadow)
}

dependencies {
	implementation(projects.lexing)
	implementation(projects.parsing)
	implementation(projects.semanticAnalyzes)
}

application {
	mainClass = "io.github.mfederczuk.systemsetupmanager.Main"
}

val copyShadowJarToRootProjectDirectory: TaskProvider<DefaultTask> by tasks.registering(DefaultTask::class) {
	inputs.file(tasks.shadowJar.map { it.outputs.files.singleFile })

	outputs.file(rootProject.layout.projectDirectory.file("${rootProject.name}.jar"))

	doFirst {
		val inputFile: File = inputs.files.singleFile
		val outputFile: File = outputs.files.singleFile

		outputFile.outputStream().buffered().use { outputStream: OutputStream ->
			inputFile.inputStream().buffered().use { inputStream: InputStream ->
				inputStream.transferTo(outputStream)
			}
		}
	}
}

tasks.assemble { dependsOn(copyShadowJarToRootProjectDirectory) }

tasks.clean { delete(copyShadowJarToRootProjectDirectory) }
