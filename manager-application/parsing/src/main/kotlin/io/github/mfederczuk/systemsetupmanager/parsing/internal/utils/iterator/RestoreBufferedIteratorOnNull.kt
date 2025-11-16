package io.github.mfederczuk.systemsetupmanager.parsing.internal.utils.iterator

/**
 * Pushes all elements consumed by [block] back to [iterator] if [block] returns `null`.
 */
internal fun <T, R : Any> restoreOnNull(iterator: BufferedIterator<T>, block: (iterator: Iterator<T>) -> R?): R? {
	return consumeOrRestore(iterator) { iterator: Iterator<T> ->
		val blockReturnValue: R? = block(iterator)

		val consumeOrRestore: ConsumeOrRestore =
			if (blockReturnValue != null) {
				ConsumeOrRestore.Consume
			} else {
				ConsumeOrRestore.Restore
			}

		consumeOrRestore to blockReturnValue
	}
}
