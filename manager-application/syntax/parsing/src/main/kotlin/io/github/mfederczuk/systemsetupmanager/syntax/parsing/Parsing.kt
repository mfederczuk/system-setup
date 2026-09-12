/*
 * Copyright (c) 2026 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.syntax.parsing

import io.github.mfederczuk.systemsetupmanager.sourceposition.SourcePosition
import io.github.mfederczuk.systemsetupmanager.syntax.ast.TasksModule
import io.github.mfederczuk.systemsetupmanager.syntax.cst.EnclosedNodesList
import io.github.mfederczuk.systemsetupmanager.syntax.cst.TasksModuleElement
import io.github.mfederczuk.systemsetupmanager.syntax.parsing.internal.TasksModuleElementParser
import io.github.mfederczuk.systemsetupmanager.syntax.parsing.internal.ast.abstractify
import io.github.mfederczuk.systemsetupmanager.syntax.parsing.internal.tokenparser.TokenParser.Companion.parseRemainingWith
import io.github.mfederczuk.systemsetupmanager.syntax.parsing.internal.utils.iterator.buffered
import io.github.mfederczuk.systemsetupmanager.syntax.token.Token
import io.github.mfederczuk.systemsetupmanager.syntax.cst.TasksModule as CstTasksModule

public fun Sequence<Token>.parse(problemReporter: ParsingProblemReporter): TasksModule {
	val elements: EnclosedNodesList<TasksModuleElement> = this
		.reportUnterminatedStringLiterals(problemReporter)
		.iterator().buffered()
		.parseRemainingWith(TasksModuleElementParser)

	return CstTasksModule(elements).abstractify(problemReporter)
}

private fun Sequence<Token>.reportUnterminatedStringLiterals(problemReporter: ParsingProblemReporter): Sequence<Token> {
	return sequence {
		var position: SourcePosition = SourcePosition.Begin

		for (token: Token in this@reportUnterminatedStringLiterals) {
			if ((token is Token.StringLiteral) && !(token.isTerminated)) {
				val error =
					UnterminatedStringLiteralError(
						sourcePosition = position,
						token = token,
					)

				problemReporter.reportProblem(error)
			}

			yield(token)

			position += token.toSourceCode()
		}
	}
}

@Deprecated(
	message = "Use overload with `ParsingProblemReporter`",
	replaceWith = ReplaceWith(
		expression = "this.parse { problem: ParsingProblem -> TODO() }",
		imports = ["io.github.mfederczuk.systemsetupmanager.syntax.parsing.ParsingProblem"],
	),
)
public fun Sequence<Token>.parse(): TasksModule {
	return this.parse {}
}
