/*
 * Copyright (c) 2025 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.parsing.old.internal

import io.github.mfederczuk.systemsetupmanager.ast.ImportString
import io.github.mfederczuk.systemsetupmanager.parsing.old.internal.parsingstream.ParsingStream
import io.github.mfederczuk.systemsetupmanager.parsing.old.internal.parsingstream.ParsingStream.ReadResult
import io.github.mfederczuk.systemsetupmanager.parsing.old.internal.parsingstream.asParsingStream
import io.github.mfederczuk.systemsetupmanager.parsing.old.internal.parsingstream.onEach
import io.github.mfederczuk.systemsetupmanager.parsing.old.issues.MultiTokenSyntaxErrorType.UnexpectedToken
import io.github.mfederczuk.systemsetupmanager.parsing.old.issues.ParsingPhaseIssue.Companion.at
import io.github.mfederczuk.systemsetupmanager.parsing.old.issues.ParsingPhaseIssueReporter
import io.github.mfederczuk.systemsetupmanager.parsing.old.issues.ParsingPhaseIssueType
import io.github.mfederczuk.systemsetupmanager.parsing.old.issues.SingleTokenSyntaxErrorType.UnknownToken
import io.github.mfederczuk.systemsetupmanager.parsing.old.issues.SingleTokenSyntaxErrorType.UnterminatedQuotedString
import io.github.mfederczuk.systemsetupmanager.sourceposition.SourcePosition
import io.github.mfederczuk.systemsetupmanager.sourceposition.SourcePositionOffset.Companion.calculateSourcePositionOffset
import io.github.mfederczuk.systemsetupmanager.token.Token

// TODO: Once we have a better name for `TasksUnit`, rename this too.
internal sealed class TasksUnitElement {

	data class ImportStatement(
		val sourceRange: OpenEndRange<SourcePosition>,
		val importString: ImportString,
	) : TasksUnitElement()

	data class TaskDefinition(
		val taskDefinition: io.github.mfederczuk.systemsetupmanager.ast.TaskDefinition,
	) : TasksUnitElement()
}

internal fun Sequence<Token>.parseToTasksUnitElements(
	issueReporter: ParsingPhaseIssueReporter,
): Sequence<TasksUnitElement> {
	return sequence {
		val tokenStream: ParsingStream<Token> = this@parseToTasksUnitElements.asTokenParsingStream()
			.onEach { tokenResult: ReadResult.Next<Token> ->
				val issueType: ParsingPhaseIssueType? =
					when {
						tokenResult.value is Token.Unknown -> UnknownToken
						tokenResult.value.isUnterminatedString() -> UnterminatedQuotedString
						else -> null
					}

				if (issueType != null) {
					issueReporter.report(issueType at tokenResult)
				}
			}

		while (true) {
			val nextToken: Token = tokenStream.read().valueOrNull
				?: break

			val nextElement: TasksUnitElement? =
				parseTokensToNextTasksUnitElement(
					firstToken = nextToken,
					otherTokens = tokenStream,
					issueReporter = issueReporter,
				)

			if (nextElement != null) {
				yield(nextElement)
			}
		}
	}
}

private tailrec fun parseTokensToNextTasksUnitElement(
	firstToken: Token,
	otherTokens: ParsingStream<Token>,
	issueReporter: ParsingPhaseIssueReporter,
): TasksUnitElement? {
	fun reportFirstTokenUnexpected() {
		issueReporter.report(UnexpectedToken at ParsingStream.ReadResult.Next(SourcePosition.Begin, firstToken))
	}

	return when (firstToken) {
		is Token.Keyword.Import -> {
			var endExclusive: SourcePosition = SourcePosition.Begin.advanceBy(firstToken.sourceCode)

			otherTokens
				.onEach { tokenResult: ReadResult.Next<Token> ->
					endExclusive = endExclusive.advanceBy(tokenResult.value.sourceCode)
				}
				.continueParsingToImportStatement(issueReporter = issueReporter/*.offsetBy(firstToken)*/)
				?.let { importString: ImportString ->
					TasksUnitElement.ImportStatement(
						sourceRange = SourcePosition.Begin..<endExclusive,
						importString = importString,
					)
				}
		}

		is Token.Keyword.Task -> {
			otherTokens.continueParsingToTaskDefinition(issueReporter = issueReporter/*.offsetBy(firstToken)*/)
				?.let(TasksUnitElement::TaskDefinition)
		}

		is Token.Keyword.Copy, is Token.Keyword.To -> {
			reportFirstTokenUnexpected()
			null
		}

		is Token.Identifier -> {
			reportFirstTokenUnexpected()
			null
		}

		is Token.StringLiteral, is Token.Brace, is Token.DoubleColon -> {
			reportFirstTokenUnexpected()
			null
		}

		is Token.Whitespace, is Token.LineComment -> {
			val secondToken: Token? = otherTokens.read().valueOrNull

			if (secondToken != null) {
				parseTokensToNextTasksUnitElement(
					firstToken = secondToken,
					otherTokens = otherTokens,
					issueReporter = issueReporter,
				)
			} else {
				null
			}
		}

		is Token.Unknown -> null

		else -> TODO()
	}
}

private fun Sequence<Token>.asTokenParsingStream(): ParsingStream<Token> {
	return this
		.asParsingStream { token: Token ->
			token.sourceCode.calculateSourcePositionOffset()
		}
}

private fun Token.isUnterminatedString(): Boolean {
	return (this is Token.StringLiteral) && !(this.isTerminated)
}
