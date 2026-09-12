/*
 * Copyright (c) 2025 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.parsing.old.internal.old

import io.github.mfederczuk.systemsetupmanager.ast.ImportString
import io.github.mfederczuk.systemsetupmanager.parsing.old.issues.ParsingPhaseIssue
import kotlinx.collections.immutable.ImmutableSet

internal sealed class ImportStatementReadingResult {

	data object End : ImportStatementReadingResult()

	data object NotAnImportStatement : ImportStatementReadingResult()

	sealed class InvalidImportStatement : ImportStatementReadingResult() {

		data class NotEnd(val issue: ParsingPhaseIssue) : InvalidImportStatement()

		data object End : InvalidImportStatement()
	}

	data class Success(
		val issue: ParsingPhaseIssue?,
		val tokens: ImmutableSet<FilteredToken>,
		val importString: ImportString,
	) : ImportStatementReadingResult()
}

internal fun BufferedSequence<FilteredToken>.readImportStatement(): ImportStatementReadingResult {
	val firstToken: FilteredToken = this.peek().getValueOrElse { return ImportStatementReadingResult.End }

	if (!(firstToken.isImportKeyword())) {
		return ImportStatementReadingResult.NotAnImportStatement
	}

	this.consume(firstToken)

	val secondToken: FilteredToken = this.read()
		.getValueOrElse { return ImportStatementReadingResult.InvalidImportStatement.End }

	when (secondToken) {
		is FilteredToken.Word -> error("Consecutive word tokens: $firstToken and $secondToken")

		is FilteredToken.QuotedString -> {
// 			NoWhitespaceBetweenImportKeywordAndQuotedString.at(firstToken, secondToken)
			TODO()

			if (secondToken.originalToken.contents.isEmpty()) {
// 				InvalidImportStatement.NotEnd(EmptyImport.at(firstToken, secondToken))
				TODO()
			} else {
// 				ImportStatementReadingResult.Success()
				TODO()
			}
		}

		is FilteredToken.Brace,
		is FilteredToken.DoubleColon,
// 			-> return InvalidImportStatement.NotEnd(UnexpectedToken at secondToken)
		-> TODO()

		is FilteredToken.Boundary -> Unit
	}

	val thirdToken: FilteredToken = this.read()
		.getValueOrElse { return ImportStatementReadingResult.InvalidImportStatement.End }

	return when (thirdToken) {
		is FilteredToken.QuotedString -> {
			if (thirdToken.originalToken.contents.isEmpty()) {
// 				InvalidImportStatement.NotEnd(EmptyImport.at(firstToken, secondToken, thirdToken))
				TODO()
			} else {
// 				ImportStatementReadingResult.Success(issue = null, )
				TODO()
			}
		}

		is FilteredToken.Word,
		is FilteredToken.Brace,
		is FilteredToken.DoubleColon,
// 			-> return InvalidImportStatement.NotEnd(UnexpectedToken at secondToken)
		-> TODO()

		is FilteredToken.Boundary -> error("Consecutive boundary tokens: $secondToken and $thirdToken")
	}
}

private fun FilteredToken.isImportKeyword(): Boolean {
	if (this !is FilteredToken.Word) {
		return false
	}

	TODO()
// 	val resolvedWord: ResolvedWord = this.originalToken.word.resolve()
//
// 	return (resolvedWord is Keyword) && (resolvedWord.type == KeywordType.Import)
}
