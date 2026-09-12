package io.github.mfederczuk.systemsetupmanager.syntax.parsing

import io.github.mfederczuk.systemsetupmanager.sourceposition.SourcePosition
import io.github.mfederczuk.systemsetupmanager.sourceposition.SourcePosition.Companion.sourcePositionRange
import io.github.mfederczuk.systemsetupmanager.sourceposition.SourcePositionRange
import io.github.mfederczuk.systemsetupmanager.syntax.token.Token
import kotlinx.collections.immutable.ImmutableSet

public sealed interface ParsingProblem {

	public val sourcePositionRange: SourcePositionRange
}

public data class UnknownTokenError(
	public val sourcePosition: SourcePosition,
	public val token: Token.Unknown,
) : ParsingProblem {

	override val sourcePositionRange: SourcePositionRange
		get() {
			return this.token.toSourceCode().sourcePositionRange(start = this.sourcePosition)
		}
}

public data class UnexpectedTokenError(
	public val sourcePosition: SourcePosition,
	public val token: Token,
) : ParsingProblem {

	override val sourcePositionRange: SourcePositionRange
		get() {
			return this.token.toSourceCode().sourcePositionRange(start = this.sourcePosition)
		}
}

public data class UnterminatedStringLiteralError(
	public val sourcePosition: SourcePosition,
	public val token: Token.StringLiteral,
) : ParsingProblem {

	override val sourcePositionRange: SourcePositionRange
		get() {
			return this.token.toSourceCode().sourcePositionRange(start = this.sourcePosition)
		}
}

public data class IllegalTaskIdentifierError(
	public val sourcePosition: SourcePosition,
	public val token: Token.Identifier,
	public val problemTypes: ImmutableSet<TaskIdentifierProblemType>,
) : ParsingProblem {

	init {
		require(problemTypes.isNotEmpty())
	}

	override val sourcePositionRange: SourcePositionRange
		get() {
			return this.token.toSourceCode().sourcePositionRange(start = this.sourcePosition)
		}
}
