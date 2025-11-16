/*
 * Copyright (c) 2025 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.ast

@JvmInline
public value class ImportString private constructor(public val value: String) {

	override fun toString(): String {
		return this.value
	}

	public companion object {

		public fun String.toImportStringOrNull(): ImportString? {
			if (this.isEmpty()) {
				return null
			}

			return ImportString(value = this)
		}
	}
}
