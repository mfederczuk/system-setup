package io.github.mfederczuk.systemsetupmanager.parsing.internal.utils.iterator

import kotlinx.collections.immutable.toImmutableList

internal enum class ConsumeOrRestore {
	Consume,
	Restore,
}

internal fun <T, R> consumeOrRestore(
	iterator: BufferedIterator<T>,
	block: (iterator: Iterator<T>) -> Pair<ConsumeOrRestore, R>,
): R {
	val elements: MutableList<T> = mutableListOf()

	val onEachIterator: Iterator<T> = iterator
		.onEach { element: T ->
			elements += element
		}

	val (consumeOrRestore: ConsumeOrRestore, value: R) = block(onEachIterator)

	when (consumeOrRestore) {
		ConsumeOrRestore.Consume -> {}
		ConsumeOrRestore.Restore -> {
			iterator.pushToBuffer(elements.toImmutableList())
		}
	}

	return value
}
