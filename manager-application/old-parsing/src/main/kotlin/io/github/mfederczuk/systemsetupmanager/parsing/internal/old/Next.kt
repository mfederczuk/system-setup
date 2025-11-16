package io.github.mfederczuk.systemsetupmanager.parsing.old.internal.old

internal sealed class Next<out V : Any, out E> {

	data class Value<V : Any>(val value: V) : Next<V, Nothing>()

	data class End<E>(val value: E) : Next<Nothing, E>()
}

internal fun <V : Any> Next(value: V): Next.Value<V> {
	return Next.Value(value)
}

internal fun <E> End(value: E): Next.End<E> {
	return Next.End(value)
}

internal val End: Next.End<Nothing?>
	get() {
		return Next.End(value = null)
	}

internal inline fun <V : Any, E> Next<V, E>.ifValue(block: (value: V) -> Unit): Next<V, E> {
	when (this) {
		is Next.Value -> block(this.value)
		is Next.End -> Unit
	}

	return this
}

internal inline fun <V : Any, E> Next<V, E>.ifEnd(block: (value: E) -> Unit): Next<V, E> {
	when (this) {
		is Next.Value -> Unit
		is Next.End -> block(this.value)
	}

	return this
}

internal inline fun <R, V : R, E> Next<V & Any, E>.getValueOrElse(block: (value: E) -> R): R {
	return when (this) {
		is Next.Value -> this.value
		is Next.End -> block(this.value)
	}
}

internal typealias NextValue<V> = Next<V, Nothing?>
internal typealias NextOptional<T> = Next<T, T?>
internal typealias NextSame<T> = Next<T, T>

@JvmName("-mapNextValue")
internal inline fun <T : Any, R : Any> NextValue<T>.map(transform: (T) -> R): NextValue<R> {
	return when (this) {
		is Next.Value -> Next.Value(transform(this.value))
		is Next.End -> this
	}
}

@JvmName("-mapNextOptional")
internal inline fun <T : Any, R : Any> NextOptional<T>.map(transform: (T) -> R): NextOptional<R> {
	return when (this) {
		is Next.Value -> Next.Value(transform(this.value))
		is Next.End -> Next.End(this.value?.let(transform))
	}
}

@JvmName("-mapNextSame")
internal inline fun <T : Any, R : Any> NextSame<T>.map(transform: (T) -> R): NextSame<R> {
	return when (this) {
		is Next.Value -> Next.Value(transform(this.value))
		is Next.End -> Next.End(transform(this.value))
	}
}

internal val <T : Any> NextSame<T>.value: T
	get() {
		return this.getValueOrElse { it }
	}

internal val <T : Any> NextOptional<T>.valueOrNull: T?
	get() {
		return this.getValueOrElse { it }
	}
