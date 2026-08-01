/*
 * Copyright (c) 2025 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.syntax.parsing.internal.utils.iterator

internal fun <T> Iterator<T>.onEach(action: (element: T) -> Unit): Iterator<T> {
	return OnEachIterator(upstream = this, action = action)
}

private data class OnEachIterator<out T>(
	private val upstream: Iterator<T>,
	private val action: (element: T) -> Unit,
) : Iterator<T> {

	override fun next(): T {
		val element: T = this.upstream.next()
		this.action(element)
		return element
	}

	override fun hasNext(): Boolean {
		return this.upstream.hasNext()
	}

	override fun toString(): String {
		return "${this.upstream}.onEach(${this.action})"
	}
}
