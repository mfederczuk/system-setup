// SPDX-License-Identifier: CC0-1.0

package io.github.mfederczuk.systemsetupmanager.parsing

import io.github.mfederczuk.systemsetupmanager.parsing.internal.utils.iterator.toImmutableList
import kotlin.test.Test
import kotlin.test.assertEquals

class IteratorToImmutableListTest {

	@Test
	fun test() {
		val list: List<Int> = listOf(0, 1, 2)

		assertEquals(list, list.iterator().toImmutableList())
	}
}
