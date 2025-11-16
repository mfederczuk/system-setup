/*
 * Copyright (c) 2025 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.token

import java.util.EnumSet

private val separatorCategories: Set<CharCategory> =
	EnumSet.of(
		CharCategory.SPACE_SEPARATOR,
		CharCategory.LINE_SEPARATOR,
		CharCategory.PARAGRAPH_SEPARATOR,
	)

private val remainingWhitespaceCharacters: Set<Char> = hashSetOf('\t', '\r', '\n')

public fun Char.isTokenWhitespace(): Boolean {
	return (this.category in separatorCategories) || (this in remainingWhitespaceCharacters)
}
