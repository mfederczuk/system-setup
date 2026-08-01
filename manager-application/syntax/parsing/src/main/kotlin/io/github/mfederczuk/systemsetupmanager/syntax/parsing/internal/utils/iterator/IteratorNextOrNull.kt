// SPDX-License-Identifier: CC0-1.0

package io.github.mfederczuk.systemsetupmanager.syntax.parsing.internal.utils.iterator

internal fun <T> Iterator<T>.nextOrNull(): T? {
	return if (this.hasNext()) {
		this.next()
	} else {
		null
	}
}
