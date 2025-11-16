package io.github.mfederczuk.systemsetupmanager.parsing.internal.utils.iterator

internal fun <T> Iterator<T>.nextOrNull(): T? {
	return if (this.hasNext()) {
		this.next()
	} else {
		null
	}
}
