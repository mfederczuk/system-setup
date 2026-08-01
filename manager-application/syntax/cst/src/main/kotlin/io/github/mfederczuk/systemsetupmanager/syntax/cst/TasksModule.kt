/*
 * Copyright (c) 2025 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.syntax.cst

public data class TasksModule(
	public val elements: EnclosedNodesList<TasksModuleElement>,
) {

	public fun toSourceCode(): String {
		return this.elements.toSourceCode()
	}
}
