package io.github.mfederczuk.systemsetupmanager.parsing.old.internal.parsingstream

import io.github.mfederczuk.systemsetupmanager.sourceposition.SourcePosition
import io.github.mfederczuk.systemsetupmanager.sourceposition.SourcePositionOffset

internal fun <T> Sequence<T>.asParsingStream(valueMeasurer: (T) -> SourcePositionOffset): ParsingStream<T> {
	return SequenceParsingStream(sequence = this, valueMeasurer)
}

private class SequenceParsingStream<T>(
	sequence: Sequence<T>,
	private val valueMeasurer: (T) -> SourcePositionOffset,
) : ParsingStream<T> {

	private data object None

	private var currentPosition: SourcePosition = SourcePosition.Begin
	private val iterator: Iterator<T> by lazy(LazyThreadSafetyMode.NONE, sequence::iterator)

	private var bufferedValue: Any? = None

	override fun read(): ParsingStream.ReadResult<T> {
		this.bufferedValue.let {
			this.bufferedValue = None

			if (it !== None) {
				@Suppress("UNCHECKED_CAST")
				return@read ParsingStream.ReadResult.Next(position = this.currentPosition, value = it as T)
			}
		}

		if (!(this.iterator.hasNext())) {
			return ParsingStream.ReadResult.Eof
		}

		val valuePosition: SourcePosition = this.currentPosition
		val value: T = this.iterator.next()

		this.currentPosition = this.currentPosition.advanceBy(this.valueMeasurer(value))

		return ParsingStream.ReadResult.Next(position = valuePosition, value)
	}

	override fun unread(value: T) {
		this.bufferedValue = value
	}
}
