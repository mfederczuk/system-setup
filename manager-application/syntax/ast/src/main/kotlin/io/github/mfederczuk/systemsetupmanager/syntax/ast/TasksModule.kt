/*
 * Copyright (c) 2026 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.syntax.ast

import io.github.mfederczuk.systemsetupmanager.utils.treeString
import kotlinx.collections.immutable.ImmutableList

public data class TasksModule(
	public val elements: ImmutableList<TasksModuleElement>,
) {

	override fun toString(): String {
		return treeString(
			"Module",
			this.elements.map(TasksModuleElement::toString),
		)
	}
}
