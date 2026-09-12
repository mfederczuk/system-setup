package io.github.mfederczuk.systemsetupmanager.sourceposition

public sealed class SourcePositionRange {

	public abstract val start: SourcePosition

	public data class Empty(override val start: SourcePosition) : SourcePositionRange() {

		override fun toString(): String {
			return this.start.toString()
		}
	}

	public data class NonEmpty(
		override val start: SourcePosition,
		override val endInclusive: SourcePosition,
	) : SourcePositionRange(), ClosedRange<SourcePosition> {

		init {
			require(start <= endInclusive)
		}

		override fun toString(): String {
			return "${this.start}-${this.endInclusive}"
		}
	}

	public companion object {

		public val SourcePositionRange.endInclusiveOrNull: SourcePosition?
			get() {
				return when (this) {
					is Empty -> null
					is NonEmpty -> this.endInclusive
				}
			}
	}
}
