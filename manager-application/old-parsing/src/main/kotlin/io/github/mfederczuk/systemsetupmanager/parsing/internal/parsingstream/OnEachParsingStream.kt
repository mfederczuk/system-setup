package io.github.mfederczuk.systemsetupmanager.parsing.old.internal.parsingstream

internal fun <T> ParsingStream<T>.onEach(action: (ParsingStream.ReadResult.Next<T>) -> Unit): ParsingStream<T> {
	return OnEachParsingStream(upstream = this, action)
}

private class OnEachParsingStream<T>(
	private val upstream: ParsingStream<T>,
	private val action: (ParsingStream.ReadResult.Next<T>) -> Unit,
) : ParsingStream<T> {

	override fun read(): ParsingStream.ReadResult<T> {
		val result: ParsingStream.ReadResult<T> = this.upstream.read()

		when (result) {
			is ParsingStream.ReadResult.Next -> this.action(result)
			is ParsingStream.ReadResult.Eof -> Unit
		}

		return result
	}

	override fun unread(value: T) {
		this.upstream.unread(value)
	}
}
