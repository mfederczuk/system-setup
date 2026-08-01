/*
 * Copyright (c) 2025 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.syntax.parsing.internal.utils.iterator

// TODO: rename to something like "limited" or "enclosed"?

internal fun <T, R> wrap(iterator: BufferedIterator<T>, until: (T) -> Boolean, block: (Iterator<T>) -> R): R {
	return block(WrappedIterator(source = iterator, isEndElement = until))
}

private data class WrappedIterator<T>(
	private val source: BufferedIterator<T>,
	private val isEndElement: (T) -> Boolean,
) : Iterator<T> {

	override fun next(): T {
		val element: T = this.source.next()

		if (this.isEndElement(element)) {
			this.source.pushToBuffer(element)
			throw NoSuchElementException()
		}

		return element
	}

	override fun hasNext(): Boolean {
		if (!(this.source.hasNext())) {
			return false
		}

		val element: T =
			try {
				this.source.next()
			} catch (_: NoSuchElementException) {
				return false
			}

		this.source.pushToBuffer(element)

		return !(this.isEndElement(element))
	}

	override fun toString(): String {
		return "wrap(${this.source}, until = ${this.isEndElement})"
	}
}
