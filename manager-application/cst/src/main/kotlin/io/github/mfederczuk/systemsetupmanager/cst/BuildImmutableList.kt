// SPDX-License-Identifier: CC0-1.0

package io.github.mfederczuk.systemsetupmanager.cst

import kotlinx.collections.immutable.ImmutableList
import kotlinx.collections.immutable.PersistentList
import kotlinx.collections.immutable.persistentListOf

internal inline fun <E> buildImmutableList(block: PersistentList.Builder<E>.() -> Unit): ImmutableList<E> {
	return persistentListOf<E>().builder().also(block).build()
}
