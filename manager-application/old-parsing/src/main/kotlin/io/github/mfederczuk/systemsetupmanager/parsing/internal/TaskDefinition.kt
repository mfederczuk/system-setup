/*
 * Copyright (c) 2025 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.parsing.old.internal

import io.github.mfederczuk.systemsetupmanager.ast.TaskDefinition
import io.github.mfederczuk.systemsetupmanager.parsing.old.internal.parsingstream.ParsingStream
import io.github.mfederczuk.systemsetupmanager.parsing.old.issues.ParsingPhaseIssueReporter
import io.github.mfederczuk.systemsetupmanager.token.Token

internal fun ParsingStream<Token>.continueParsingToTaskDefinition(
	issueReporter: ParsingPhaseIssueReporter,
): TaskDefinition? {
	return null // TODO
}

private fun ParsingStream<Token>.parseToTaskAction() {}
