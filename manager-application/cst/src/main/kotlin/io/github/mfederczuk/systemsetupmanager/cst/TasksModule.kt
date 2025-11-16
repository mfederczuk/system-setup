/*
 * Copyright (c) 2025 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.cst

public data class TasksModule(
	public val elements: EnclosedNodesList<TasksModuleElementNode>,
) {

	public fun toSourceCode(): String {
		return this.elements.toSourceCode()
	}
}
