/*
 * Copyright (c) 2026 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.utils

public fun treeString(root: String, branches: List<String>): String {
	val sb = StringBuilder()

	sb.append(root)

	branches.forEachIndexed { index: Int, branch: String ->
		val branchPrefix: Char
		val continuationLinePrefix: Char
		if (index != branches.lastIndex) {
			branchPrefix = '├'
			continuationLinePrefix = '│'
		} else {
			branchPrefix = '└'
			continuationLinePrefix = ' '
		}

		sb.append('\n')
			.append(branchPrefix).append("── ")
			.append(branch.replace("\n", "\n$continuationLinePrefix   "))
	}

	return sb.toString()
}

public fun treeString(root: String, vararg branches: String): String {
	return treeString(root, branches.toList())
}
