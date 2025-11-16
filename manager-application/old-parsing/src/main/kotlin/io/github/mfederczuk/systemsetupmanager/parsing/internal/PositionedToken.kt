package io.github.mfederczuk.systemsetupmanager.parsing.old.internal

import io.github.mfederczuk.systemsetupmanager.sourceposition.SourcePosition
import io.github.mfederczuk.systemsetupmanager.token.Token

internal data class PositionedToken(
	val position: SourcePosition,
	val token: Token,
) {

	fun calculatePositionRange(): OpenEndRange<SourcePosition> {
		return (this.position)..<(this.position.advanceBy(this.token.sourceCode))
	}

	companion object {

		infix fun Token.at(position: SourcePosition): PositionedToken {
			return PositionedToken(position = position, token = this@at)
		}

		fun Sequence<Token>.positioned(): Sequence<PositionedToken> {
			return sequence {
				var currentPosition: SourcePosition = SourcePosition.Begin

				for (token: Token in this@positioned) {
					yield(token at currentPosition)
					currentPosition = currentPosition.advanceBy(token.sourceCode)
				}
			}
		}
	}
}
