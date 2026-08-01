/*
 * Copyright (c) 2025 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.syntax.lexing.internal

import io.github.mfederczuk.systemsetupmanager.syntax.token.Token

@JvmInline
internal value class UnknownTokenBuilder private constructor(private val stringBuilder: StringBuilder) {

	constructor() : this(StringBuilder())

	fun append(char: Char) {
		this.stringBuilder.append(char)
	}

	fun build(): Token.Unknown? {
		val string: String = this.stringBuilder.toString()

		return if (string.isNotEmpty()) {
			Token.Unknown(sourceCode = string)
		} else {
			null
		}
	}
}
