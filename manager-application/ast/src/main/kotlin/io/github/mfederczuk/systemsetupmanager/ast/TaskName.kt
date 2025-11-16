/*
 * Copyright (c) 2025 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.ast

@JvmInline
public value class TaskName private constructor(private val nameString: String) {

	override fun toString(): String {
		return this.nameString
	}

	public companion object {

		public fun String.toTaskNameOrNull(): TaskName? {
			if (!(this.isValidTaskName())) {
				return null
			}

			return TaskName(nameString = this)
		}
	}
}

private fun String.isValidTaskName(): Boolean {
	val firstChar: Char = this.firstOrNull() ?: return false

	return (firstChar in 'a'..'z') && this.drop(1)
		.split('_')
		.all { component: String ->
			component.isNotEmpty() && component.all { ch: Char ->
				ch in 'a'..'z' || ch in '0'..'9'
			}
		}
}
