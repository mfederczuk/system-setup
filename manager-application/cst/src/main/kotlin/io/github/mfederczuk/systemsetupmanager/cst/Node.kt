/*
 * Copyright (c) 2025 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.cst

import io.github.mfederczuk.systemsetupmanager.token.Token
import kotlinx.collections.immutable.ImmutableList
import kotlinx.collections.immutable.PersistentList

public sealed class Node {

	internal abstract fun combineTokens(): ImmutableList<Token>

	public fun toSourceCode(): String {
		return this.combineTokens().joinToString(separator = "", transform = Token::toSourceCode)
	}

	internal companion object {

		fun PersistentList.Builder<Token>.add(node: Node) {
			this.addAll(node.combineTokens())
		}
	}
}
