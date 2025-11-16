/*
 * Copyright (c) 2025 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.parsing.internal

import io.github.mfederczuk.systemsetupmanager.cst.TaskActionNode
import io.github.mfederczuk.systemsetupmanager.parsing.internal.tokenparser.TokenParser
import io.github.mfederczuk.systemsetupmanager.parsing.internal.tokenparser.multiTokenParserOf

internal val TaskActionParser: TokenParser<TaskActionNode> =
	multiTokenParserOf(
		CopyingTaskActionParser,
		TaskExecutionTaskActionParser,
	)
