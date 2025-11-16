package io.github.mfederczuk.systemsetupmanager.parsing.old.internal.parsingstream

import io.github.mfederczuk.systemsetupmanager.sourceposition.SourcePosition

internal interface ParsingStream<T> {

	sealed class ReadResult<out T> {

		data class Next<T>(
			val position: SourcePosition,
			val value: T,
		) : ReadResult<T>()

		data object Eof : ReadResult<Nothing>()

		val valueOrNull: T?
			get() {
				return when (this) {
					is Next -> this.value
					is Eof -> null
				}
			}
	}

	fun read(): ReadResult<T>

	fun unread(value: T)
}
