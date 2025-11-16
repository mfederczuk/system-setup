/*
 * Copyright (c) 2025 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.parsing

import io.github.mfederczuk.systemsetupmanager.cst.EnclosedNodesList
import io.github.mfederczuk.systemsetupmanager.cst.TasksModule
import io.github.mfederczuk.systemsetupmanager.cst.TasksModuleElementNode
import io.github.mfederczuk.systemsetupmanager.parsing.internal.TasksModuleElementParser
import io.github.mfederczuk.systemsetupmanager.parsing.internal.tokenparser.TokenParser.Companion.parseRemainingWith
import io.github.mfederczuk.systemsetupmanager.parsing.internal.utils.iterator.buffered
import io.github.mfederczuk.systemsetupmanager.token.Token

// TODO: report errors and warnings

public fun Sequence<Token>.parse(): TasksModule {
	val elements: EnclosedNodesList<TasksModuleElementNode> = this.iterator().buffered()
		.parseRemainingWith(TasksModuleElementParser)

	return TasksModule(elements)
}
