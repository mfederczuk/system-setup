// SPDX-License-Identifier: CC0-1.0

package io.github.mfederczuk.systemsetupmanager.parsing.internal.utils.iterator

import kotlinx.collections.immutable.ImmutableList
import kotlinx.collections.immutable.PersistentList
import kotlinx.collections.immutable.persistentListOf

internal fun <T> Iterator<T>.toImmutableList(): ImmutableList<T> {
	val list: PersistentList.Builder<T> = persistentListOf<T>().builder()

	for (element: T in this) {
		list += element
	}

	return list.build()
}
