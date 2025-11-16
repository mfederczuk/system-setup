package io.github.mfederczuk.systemsetupmanager.parsing.internal.utils.iterator

import kotlinx.collections.immutable.ImmutableList
import kotlinx.collections.immutable.persistentListOf

internal interface BufferedIterator<T> : Iterator<T> {

	fun pushToBuffer(elements: ImmutableList<T>)

	fun pushToBuffer(element: T) {
		this.pushToBuffer(persistentListOf(element))
	}
}

internal fun <T> Iterator<T>.buffered(): BufferedIterator<T> {
	return BufferedIteratorImpl(source = this)
}

private class BufferedIteratorImpl<T>(private val source: Iterator<T>) : BufferedIterator<T> {

	private val buffer: MutableList<T> = mutableListOf()

	override fun next(): T {
		if (this.buffer.isNotEmpty()) {
			return this.buffer.removeAt(this.buffer.lastIndex)
		}

		return this.source.next()
	}

	override fun hasNext(): Boolean {
		if (this.buffer.isNotEmpty()) {
			return true
		}

		return this.source.hasNext()
	}

	override fun pushToBuffer(elements: ImmutableList<T>) {
		this.buffer += elements.asReversed()
	}

	override fun pushToBuffer(element: T) {
		this.buffer += element
	}
}
