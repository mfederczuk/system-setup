// SPDX-License-Identifier: CC0-1.0

package io.github.mfederczuk.systemsetupmanager.syntax.ast

import io.github.mfederczuk.systemsetupmanager.sourceposition.SourcePositionRange

public sealed interface Node {

	public val sourcePositionRange: SourcePositionRange
}
