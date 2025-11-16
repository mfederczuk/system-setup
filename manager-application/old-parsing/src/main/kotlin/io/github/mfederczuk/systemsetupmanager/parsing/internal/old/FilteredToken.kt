package io.github.mfederczuk.systemsetupmanager.parsing.old.internal.old

import io.github.mfederczuk.systemsetupmanager.parsing.old.internal.PositionedToken
import io.github.mfederczuk.systemsetupmanager.sourceposition.SourcePosition
import io.github.mfederczuk.systemsetupmanager.token.Token
import kotlinx.collections.immutable.ImmutableList
import kotlinx.collections.immutable.PersistentList
import kotlinx.collections.immutable.persistentListOf
import kotlinx.collections.immutable.toImmutableList

internal sealed class FilteredToken {

	abstract val sourcePosition: SourcePosition

	data class Word(
		override val sourcePosition: SourcePosition,
		val originalToken: Any,
	) : FilteredToken()

	data class QuotedString(
		override val sourcePosition: SourcePosition,
		val originalToken: Token.StringLiteral,
	) : FilteredToken()

	data class Brace(
		override val sourcePosition: SourcePosition,
		val originalToken: Token.Brace,
	) : FilteredToken()

	data class DoubleColon(
		override val sourcePosition: SourcePosition,
		val originalToken: Token.DoubleColon,
	) : FilteredToken()

	data class Boundary(
		override val sourcePosition: SourcePosition,
		val originalTokens: ImmutableList<Token>,
	) : FilteredToken() {

		init {
			require(originalTokens.isNotEmpty())
		}

		fun containsNewline(): Boolean {
			return this.originalTokens
				.any { token: Token ->
					(token is Token.Whitespace) && ('\n' in token.whitespaceString)
				}
		}
	}
}

internal fun Sequence<PositionedToken>.filter(): Sequence<FilteredToken> {
	return sequence {
		var boundaryAccumulator: FilteredToken.Boundary? = null

		for (positionedToken: PositionedToken in this@filter) {
			val filteredToken: FilteredToken = positionedToken.toFilteredToken()
				?: continue

			if (filteredToken is FilteredToken.Boundary) {
				boundaryAccumulator = boundaryAccumulator
					?.copy(originalTokens = boundaryAccumulator.originalTokens + filteredToken.originalTokens)
					?: filteredToken

				continue
			}

			boundaryAccumulator?.let { yield(it) }
			yield(filteredToken)
		}

		boundaryAccumulator?.let { yield(it) }
	}
}

private fun PositionedToken.toFilteredToken(): FilteredToken? {
	return when (val token: Token = this.token) {
//		is Token.Word -> FilteredToken.Word(this.position, token)
		is Token.StringLiteral -> FilteredToken.QuotedString(this.position, token)
		is Token.Brace -> FilteredToken.Brace(this.position, token)
		is Token.DoubleColon -> FilteredToken.DoubleColon(this.position, token)
		is Token.Whitespace, is Token.Unknown -> FilteredToken.Boundary(this.position, persistentListOf(token))
		is Token.LineComment -> null
		else -> TODO()
	}
}

private operator fun <E> ImmutableList<E>.plus(elements: Collection<E>): ImmutableList<E> {
	if (this is PersistentList) {
		return this.addAll(elements)
	}

	return ((this as List<E>) + elements).toImmutableList()
}
