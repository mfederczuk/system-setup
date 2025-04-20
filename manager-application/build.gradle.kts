import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
	application
	kotlin("jvm") version "2.1.20"
	id("com.gradleup.shadow") version "9.0.0-beta12"
}

java {
	targetCompatibility = JavaVersion.VERSION_21
	sourceCompatibility = targetCompatibility
}

kotlin {
	compilerOptions {
		jvmTarget = provider { JvmTarget.fromTarget(java.targetCompatibility.toString()) }
		extraWarnings = true
	}
}

dependencies {
	implementation("org.jetbrains.kotlinx:kotlinx-collections-immutable:0.3.8")
}

application {
	// Define the main class for the application.
	mainClass = "io.github.mfederczuk.systemsetupmanager.Main"
}
