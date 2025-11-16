/*
 * Copyright (c) 2025 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.parsing.old.issues
/*
import io.github.mfederczuk.systemsetupmanager.sourceposition.SourcePosition
import io.github.mfederczuk.systemsetupmanager.sourceposition.SourcePositionOffset

public fun ParsingPhaseIssueReporter.offsetBy(offset: SourcePositionOffset): ParsingPhaseIssueReporter {
	return OffsetParsingPhaseIssueReporter(delegatedReporter = this, offset)
}

private class OffsetParsingPhaseIssueReporter(
	private val delegatedReporter: ParsingPhaseIssueReporter,
	private val offset: SourcePositionOffset,
) : ParsingPhaseIssueReporter {

	override fun report(issue: ParsingPhaseIssue) {
		val offsetIssue: ParsingPhaseIssue = issue.offsetBy(this.offset)
		this.delegatedReporter.report(offsetIssue)
	}
}

private fun ParsingPhaseIssue.offsetBy(offset: SourcePositionOffset): ParsingPhaseIssue {
	return this.copy(sourceRange = this.sourceRange.offsetBy(offset))
}

private fun OpenEndRange<SourcePosition>.offsetBy(offset: SourcePositionOffset): OpenEndRange<SourcePosition> {
	val offsetStart: SourcePosition = this.start.advanceBy(offset)
	val offsetEndExclusive: SourcePosition = this.endExclusive.advanceBy(offset)

	return offsetStart..<offsetEndExclusive
}
*/
