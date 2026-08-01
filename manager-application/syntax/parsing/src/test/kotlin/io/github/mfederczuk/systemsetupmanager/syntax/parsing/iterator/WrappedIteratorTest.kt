// SPDX-License-Identifier: CC0-1.0

package io.github.mfederczuk.systemsetupmanager.syntax.parsing.iterator

import io.github.mfederczuk.systemsetupmanager.syntax.parsing.internal.utils.iterator.BufferedIterator
import io.github.mfederczuk.systemsetupmanager.syntax.parsing.internal.utils.iterator.buffered
import io.github.mfederczuk.systemsetupmanager.syntax.parsing.internal.utils.iterator.toImmutableList
import io.github.mfederczuk.systemsetupmanager.syntax.parsing.internal.utils.iterator.wrap
import kotlinx.collections.immutable.ImmutableList
import kotlin.test.Test
import kotlin.test.assertEquals

class WrappedIteratorTest {

	private companion object {

		const val END: Char = '|'
	}

	@Test
	fun `The iterator passed to the block only contain the elements before the 'until' predicate`() {
		val expected: List<Char> = listOf('a', 'b', 'c')

		val actual: ImmutableList<Char> =
			wrap((expected + END).iterator().buffered(), until = { it == END }) { iterator: Iterator<Char> ->
				iterator.toImmutableList()
			}

		assertEquals(expected, actual)
	}

	@Test
	fun `The end element is not consumed`() {
		val endAndAfter: List<Char> = listOf(END, 'd', 'e', 'f')

		val iterator: BufferedIterator<Char> = (listOf('a', 'b', 'c') + endAndAfter).iterator().buffered()

		wrap(iterator, until = { it == END }) { iterator: Iterator<Char> ->
			iterator.consume()
		}

		assertEquals(endAndAfter, iterator.toImmutableList())
	}
}

private fun <T> Iterator<T>.consume() {
	while (this.hasNext()) {
		val _: T = this.next()
	}
}
