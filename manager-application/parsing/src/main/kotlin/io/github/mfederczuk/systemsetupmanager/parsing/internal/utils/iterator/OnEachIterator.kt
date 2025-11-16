package io.github.mfederczuk.systemsetupmanager.parsing.internal.utils.iterator

internal fun <T> Iterator<T>.onEach(action: (element: T) -> Unit): Iterator<T> {
	return OnEachIterator(upstream = this, action = action)
}

private class OnEachIterator<out T>(
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
}
