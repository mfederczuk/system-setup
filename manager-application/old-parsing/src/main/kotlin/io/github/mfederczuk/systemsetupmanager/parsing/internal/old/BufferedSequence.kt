package io.github.mfederczuk.systemsetupmanager.parsing.old.internal.old

import kotlinx.collections.immutable.ImmutableList
import kotlinx.collections.immutable.toImmutableList

internal class BufferedSequence<T : Any>(upstream: Sequence<T>) {

	private val iterator: Iterator<T> by lazy(LazyThreadSafetyMode.NONE, upstream::iterator)

	private var bufferedValue: T? = null

	fun read(): NextValue<T> {
		this.bufferedValue?.let {
			this.bufferedValue = null
			return Next(it)
		}

		return this.readUnbuffered()
	}

	fun peek(): NextValue<T> {
		this.bufferedValue?.let { return Next(it) }

		return this.readUnbuffered()
			.ifValue { value: T ->
				this.bufferedValue = value
			}
	}

	fun consume(value: T) {
		check(this.bufferedValue == value)
		this.bufferedValue = null
	}

	private fun readUnbuffered(): Next<T, Nothing?> {
		if (!(this.iterator.hasNext())) {
			return End
		}

		return Next(this.iterator.next())
	}
}

internal inline fun <T : Any> BufferedSequence<T>.readWhile(
	crossinline condition: (T) -> Boolean,
): NextSame<ImmutableList<T>> {
	val values: MutableList<T> = mutableListOf()

	while (true) {
		val next: NextValue<T> = this.read()

		when (next) {
			is Next.Value -> {
				values += next.value

				if (!(condition(next.value))) {
					return Next(values.toImmutableList())
				}
			}

			is Next.End -> return End(values.toImmutableList())
		}
	}
}
