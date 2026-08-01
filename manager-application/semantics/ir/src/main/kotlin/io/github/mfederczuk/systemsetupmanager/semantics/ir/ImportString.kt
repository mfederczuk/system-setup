/*
 * Copyright (c) 2026 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.semantics.ir

@JvmInline
public value class ImportString private constructor(public val value: String) {

	init {
		require(value.isNotEmpty())
	}

	override fun toString(): String {
		return this.value
	}

	public companion object {

		public fun String.toImportStringOrNull(): ImportString? {
			return if (this.isNotEmpty()) {
				ImportString(value = this)
			} else {
				null
			}
		}
	}
}
