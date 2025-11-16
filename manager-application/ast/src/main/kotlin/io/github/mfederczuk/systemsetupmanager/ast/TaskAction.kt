/*
 * Copyright (c) 2025 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.ast

public sealed class TaskAction {

	public data class Copying(
		public val source: String,
		public val target: String,
	) : TaskAction() {

		init {
			require(source.isNotEmpty())
			require(target.isNotEmpty())
		}
	}

	public data class TaskExecution(
		public val namespace: ImportString,
		public val taskName: TaskName,
	) : TaskAction()
}
