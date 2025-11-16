package io.github.mfederczuk.systemsetupmanager.parsing.old.internal.parsingstream

internal fun <T> ParsingStream<T>.asSequence(): Sequence<T> {
	return ParsingStreamSequence(upstream = this).constrainOnce()
}

private class ParsingStreamSequence<T>(private val upstream: ParsingStream<T>) : Sequence<T> {

	override fun iterator(): Iterator<T> {
		return ParsingStreamIterator(upstream = this.upstream)
	}
}

private class ParsingStreamIterator<T>(private val upstream: ParsingStream<T>) : Iterator<T> {

	private var bufferedResult: ParsingStream.ReadResult<T>? = null

	override fun next(): T {
		val result: ParsingStream.ReadResult<T> = this.bufferedResult?.also { this.bufferedResult = null }
			?: this.upstream.read()

		when (result) {
			is ParsingStream.ReadResult.Next -> return result.value
			is ParsingStream.ReadResult.Eof -> throw NoSuchElementException()
		}
	}

	override fun hasNext(): Boolean {
		val result: ParsingStream.ReadResult<T> = this.bufferedResult
			?: this.upstream.read().also { this.bufferedResult = it }

		return when (result) {
			is ParsingStream.ReadResult.Next -> true
			is ParsingStream.ReadResult.Eof -> false
		}
	}
}
