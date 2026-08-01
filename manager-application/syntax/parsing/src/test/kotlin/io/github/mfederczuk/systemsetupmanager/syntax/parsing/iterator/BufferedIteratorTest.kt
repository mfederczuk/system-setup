// SPDX-License-Identifier: CC0-1.0

package io.github.mfederczuk.systemsetupmanager.syntax.parsing.iterator

import io.github.mfederczuk.systemsetupmanager.syntax.parsing.internal.utils.iterator.BufferedIterator
import io.github.mfederczuk.systemsetupmanager.syntax.parsing.internal.utils.iterator.buffered
import io.github.mfederczuk.systemsetupmanager.syntax.parsing.internal.utils.iterator.toImmutableList
import kotlinx.collections.immutable.ImmutableList
import kotlinx.collections.immutable.persistentListOf
import kotlin.test.Test
import kotlin.test.assertEquals

class BufferedIteratorTest {

	@Test
	fun `A BufferedIterator correctly iterates through its source`() {
		val list: ImmutableList<Int> = persistentListOf(0, 1, 2)

		assertEquals(
			list,
			list.iterator().buffered().toImmutableList(),
		)
	}

	@Test
	fun `The value passed to pushToBuffer() is the next returned from next()`() {
		val iterator: BufferedIterator<String> = iterator<Nothing> {}.buffered()

		iterator.pushToBuffer("foo")

		assertEquals(
			"foo",
			iterator.next(),
		)
	}

	@Test
	fun `The elements of the list passed to pushToBufer() are the next to be returned from next() in reverse order`() {
		val iterator: BufferedIterator<Int> = iterator<Nothing> {}.buffered()

		val list: ImmutableList<Int> = persistentListOf(2, 1, 0)

		iterator.pushToBuffer(list)

		assertEquals(
			list,
			iterator.toImmutableList(),
		)
	}
}
