/*
 * Copyright (c) 2025 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.syntax.parsing.internal

import io.github.mfederczuk.systemsetupmanager.syntax.cst.TasksModuleElement
import io.github.mfederczuk.systemsetupmanager.syntax.parsing.internal.tokenparser.TokenParser
import io.github.mfederczuk.systemsetupmanager.syntax.parsing.internal.tokenparser.multiTokenParserOf

internal val TasksModuleElementParser: TokenParser<TasksModuleElement> =
	multiTokenParserOf(
		ImportStatementParser,
		TaskDefinitionParser,
	)
