/*
 * Copyright (c) 2026 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.semantics.ir

import io.github.mfederczuk.systemsetupmanager.syntax.patterns.Identifier
import io.github.mfederczuk.systemsetupmanager.utils.treeString
import kotlinx.collections.immutable.ImmutableList

public data class TaskDefinition(
	public val identifier: Identifier,
	public val actions: ImmutableList<TaskAction>,
) {

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
