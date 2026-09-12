/*
 * Copyright (c) 2026 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.syntax.ast

import io.github.mfederczuk.systemsetupmanager.sourceposition.SourcePositionRange
import io.github.mfederczuk.systemsetupmanager.syntax.patterns.Identifier
import io.github.mfederczuk.systemsetupmanager.utils.quoted
import io.github.mfederczuk.systemsetupmanager.utils.treeString

public sealed class TaskAction : Node {

	public data class Copying(
		override val sourcePositionRange: SourcePositionRange,
		public val source: String,
		public val target: String,
	) : TaskAction() {

		override fun toString(): String {
			return treeString(
				"Copy",
				"source: ${this.source.quoted()}",
				"target: ${this.target.quoted()}",
			)
		}
	}

	public data class TaskExecution(
		override val sourcePositionRange: SourcePositionRange,
		public val namespace: String,
		public val taskIdentifier: Identifier,
	) : TaskAction() {

		override fun toString(): String {
			return treeString(
				"TaskExecution",
				"namespace: ${this.namespace.quoted()}",
				"taskIdentifier: ${this.taskIdentifier}",
			)
		}
	}
}
