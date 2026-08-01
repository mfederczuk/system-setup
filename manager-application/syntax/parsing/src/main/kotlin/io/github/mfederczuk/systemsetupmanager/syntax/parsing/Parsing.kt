/*
 * Copyright (c) 2025 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.syntax.parsing

import io.github.mfederczuk.systemsetupmanager.syntax.ast.TasksModule
import io.github.mfederczuk.systemsetupmanager.syntax.cst.EnclosedNodesList
import io.github.mfederczuk.systemsetupmanager.syntax.cst.TasksModuleElement
import io.github.mfederczuk.systemsetupmanager.syntax.parsing.internal.TasksModuleElementParser
import io.github.mfederczuk.systemsetupmanager.syntax.parsing.internal.ast.abstractify
import io.github.mfederczuk.systemsetupmanager.syntax.parsing.internal.tokenparser.TokenParser.Companion.parseRemainingWith
import io.github.mfederczuk.systemsetupmanager.syntax.parsing.internal.utils.iterator.buffered
import io.github.mfederczuk.systemsetupmanager.syntax.token.Token
import io.github.mfederczuk.systemsetupmanager.syntax.cst.TasksModule as CstTasksModule

// TODO: report errors and warnings

public fun Sequence<Token>.parse(): TasksModule {
	val elements: EnclosedNodesList<TasksModuleElement> = this.iterator().buffered()
		.parseRemainingWith(TasksModuleElementParser)

	return CstTasksModule(elements).abstractify()
}
