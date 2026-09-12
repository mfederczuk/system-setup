/*
 * Copyright (c) 2026 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.syntax.ast

import io.github.mfederczuk.systemsetupmanager.sourceposition.SourcePositionRange
import io.github.mfederczuk.systemsetupmanager.syntax.patterns.Identifier
import io.github.mfederczuk.systemsetupmanager.utils.quoted
import io.github.mfederczuk.systemsetupmanager.utils.treeString
import kotlinx.collections.immutable.ImmutableList

public sealed class TasksModuleElement : Node {

	public data class ImportStatement(
		override val sourcePositionRange: SourcePositionRange,
		public val string: String,
	) : TasksModuleElement() {

		override fun toString(): String {
			return treeString(
				"Import",
				this.string.quoted(),
			)
		}
	}

	public data class TaskDefinition(
		override val sourcePositionRange: SourcePositionRange,
		public val identifier: Identifier,
		public val actions: ImmutableList<TaskAction>,
	) : TasksModuleElement() {

		override fun toString(): String {
			return treeString(
				"Task",
				"identifier: ${this.identifier}",
				treeString(
					"actions:",
					this.actions.map(TaskAction::toString),
				),
			)
		}
	}
}
