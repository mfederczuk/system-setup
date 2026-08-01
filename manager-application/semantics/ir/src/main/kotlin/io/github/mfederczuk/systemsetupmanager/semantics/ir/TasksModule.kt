/*
 * Copyright (c) 2026 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.semantics.ir

import io.github.mfederczuk.systemsetupmanager.utils.quoted
import io.github.mfederczuk.systemsetupmanager.utils.treeString
import kotlinx.collections.immutable.ImmutableList
import kotlinx.collections.immutable.ImmutableMap

public data class TasksModule(
	public val importedModules: ImmutableMap<ImportString, TasksModule>,
	public val taskDefinitions: ImmutableList<TaskDefinition>,
) {

	override fun toString(): String {
		return treeString(
			"Module",
			treeString(
				"importedModules:",
				this.importedModules
					.map { (namespace: ImportString, module: TasksModule) ->
						val prefix = "${namespace.value.quoted()}: "

						prefix + module.toString()
							.replace("\n", "\n" + " ".repeat(prefix.length))
					},
			),
			treeString(
				"taskDefinitions:",
				this.taskDefinitions.map(TaskDefinition::toString),
			),
		)
	}
}
