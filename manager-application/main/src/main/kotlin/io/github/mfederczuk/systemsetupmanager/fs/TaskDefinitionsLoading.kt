package io.github.mfederczuk.systemsetupmanager.fs

import io.github.mfederczuk.systemsetupmanager.semantics.ir.ImportString
import kotlinx.collections.immutable.ImmutableList
import kotlinx.collections.immutable.ImmutableMap
import kotlinx.collections.immutable.toImmutableList
import java.io.File
import java.nio.file.Path
import java.util.EnumMap
import kotlin.io.path.div
import io.github.mfederczuk.systemsetupmanager.semantics.ir.TaskAction as TaskActionIr
import io.github.mfederczuk.systemsetupmanager.semantics.ir.TaskDefinition as TaskDefinitionIr
import io.github.mfederczuk.systemsetupmanager.semantics.ir.TasksModule as TasksModuleIr

private val EnvironmentVariableNames: Map<TemplatedPath.Root, String> =
	run {
		val map: MutableMap<TemplatedPath.Root, String> = EnumMap(TemplatedPath.Root::class.java)

		map[TemplatedPath.Root.UserHome] = "HOME"
		map[TemplatedPath.Root.ConfigHome] = "XDG_CONFIG_HOME"

		map
	}

fun loadTaskDefinitionsFrom(moduleDirectory: Path): ImmutableList<FsTaskDefinition> {
	val module: TasksModuleIr = loadTasksModuleFrom(moduleDirectory)

	return module.taskDefinitions
		.map { taskDefinition: TaskDefinitionIr ->
			taskDefinition.toFsTaskDefinition(moduleDirectory, module.importedModules)
		}
		.toImmutableList()
}

private fun TaskDefinitionIr.toFsTaskDefinition(
	moduleDirectory: Path,
	importedModules: ImmutableMap<ImportString, TasksModuleIr>,
): FsTaskDefinition {
	return FsTaskDefinition(
		identifier = this.identifier,
		actions = this.actions
			.map { action: TaskActionIr ->
				action.toFsTaskAction(moduleDirectory, importedModules)
			}
			.toImmutableList(),
	)
}

private fun TaskActionIr.toFsTaskAction(
	moduleDirectory: Path,
	importedModules: ImmutableMap<ImportString, TasksModuleIr>,
): FsTaskAction {
	return when (this) {
		is TaskActionIr.Copying -> this.toFsCopyingAction(moduleDirectory)
		is TaskActionIr.TaskExecution -> this.toFsTaskExecutionAction(moduleDirectory, importedModules)
	}
}

private fun TaskActionIr.Copying.toFsCopyingAction(moduleDirectory: Path): FsTaskAction.Copying {
	return FsTaskAction.Copying(
		sourcePath = moduleDirectory / this.source.normalizePathComponentSeparators(),
		targetPath = this.target.toTemplatedPath(),
	)
}

private fun TaskActionIr.TaskExecution.toFsTaskExecutionAction(
	moduleDirectory: Path,
	importedModules: ImmutableMap<ImportString, TasksModuleIr>,
): FsTaskAction.TaskExecution {
	val taskModule: TasksModuleIr = importedModules.getValue(this.namespace)

	val task: FsTaskDefinition = taskModule.taskDefinitions
		.first { taskDefinition: TaskDefinitionIr ->
			taskDefinition.identifier == this.taskIdentifier
		}
		.toFsTaskDefinition(
			moduleDirectory = moduleDirectory / this.namespace,
			importedModules = taskModule.importedModules,
		)

	return FsTaskAction.TaskExecution(
		namespace = this.namespace.value,
		task = task,
	)
}

private fun String.normalizePathComponentSeparators(): String {
	return this.replace('/', File.separatorChar)
}

private fun String.toTemplatedPath(): TemplatedPath {
	// TODO
	return EnvironmentVariableNames
		.firstNotNullOfOrNull { (root: TemplatedPath.Root, envVarName: String) ->
			val prefix = "$$envVarName"

			when {
				this.startsWith("$prefix/") -> {
					val relativePath: Path = this.removePrefix("$prefix/")
						.replace('/', File.separatorChar)
						.let(Path::of)

					TemplatedPath(root, relativePath)
				}

				(this == prefix) -> TemplatedPath(root, relativePath = Path.of("."))

				else -> null
			}
		}
		?: error("Invalid path: \"$this\"")
}

private operator fun Path.div(importString: ImportString): Path {
	return this / importString.value
}
