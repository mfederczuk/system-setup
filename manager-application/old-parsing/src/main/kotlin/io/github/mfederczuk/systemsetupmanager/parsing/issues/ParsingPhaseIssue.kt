/*
 * Copyright (c) 2025 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.parsing.old.issues

import io.github.mfederczuk.systemsetupmanager.parsing.old.internal.parsingstream.ParsingStream
import io.github.mfederczuk.systemsetupmanager.sourceposition.SourcePosition
import io.github.mfederczuk.systemsetupmanager.token.Token

public data class ParsingPhaseIssue(
	public val sourceRange: OpenEndRange<SourcePosition>,
	public val type: ParsingPhaseIssueType,
) {

	public companion object {

		public infix fun ParsingPhaseIssueType.at(sourceRange: OpenEndRange<SourcePosition>): ParsingPhaseIssue {
			return ParsingPhaseIssue(sourceRange = sourceRange, type = this@at)
		}

// 		internal infix fun ParsingPhaseIssueType.at(positionedToken: PositionedToken): ParsingPhaseIssue {
// 			return this@at at positionedToken.calculatePositionRange()
// 		}

		internal infix fun ParsingPhaseIssueType.at(result: ParsingStream.ReadResult.Next<Token>): ParsingPhaseIssue {
			return this@at at result.calculatePositionRange()
		}
	}
}

private fun ParsingStream.ReadResult.Next<Token>.calculatePositionRange(): OpenEndRange<SourcePosition> {
	return (this.position)..<(this.position.advanceBy(this.value.sourceCode))
}
