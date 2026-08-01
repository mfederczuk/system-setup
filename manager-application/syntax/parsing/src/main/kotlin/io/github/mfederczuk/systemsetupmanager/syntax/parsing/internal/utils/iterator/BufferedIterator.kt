/*
 * Copyright (c) 2026 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.syntax.parsing.internal.utils.iterator

import kotlinx.collections.immutable.ImmutableList
import kotlinx.collections.immutable.persistentListOf

internal interface BufferedIterator<T> : Iterator<T> {

	/**
	 * Pushes [elements] onto the internal buffer.
	 * The last element in [elements] is the first to be returned from [next()][next].
	 *
	 * This is equivalent to:
	 *
	 * ```
	 * for (element in elements) {
	 * 	bufferedIterator.pushToBuffer(element)
	 * }
	 * ```
	 */
	fun pushToBuffer(elements: ImmutableList<T>)

	/**
	 * Pushes [element] onto the internal buffer,
	 * which causes the next invocation of [next()][next] to return [element].
	 */
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

	override fun toString(): String {
		return "${this.source}.buffered()"
	}
}
