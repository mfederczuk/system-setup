/*
 * Copyright (c) 2025 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.syntax.parsing.internal

import io.github.mfederczuk.systemsetupmanager.syntax.cst.TaskAction
import io.github.mfederczuk.systemsetupmanager.syntax.parsing.internal.tokenparser.TokenParser
import io.github.mfederczuk.systemsetupmanager.syntax.parsing.internal.tokenparser.multiTokenParserOf

internal val TaskActionParser: TokenParser<TaskAction> =
	multiTokenParserOf(
		CopyingTaskActionParser,
		TaskExecutionTaskActionParser,
	)
