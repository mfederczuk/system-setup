/*
 * Copyright (c) 2025 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.sourceposition

import io.github.mfederczuk.systemsetupmanager.sourceposition.SourcePositionOffset.Companion.calculateSourcePositionOffset
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class SourcePositionOffsetTest {

	// region .toComponents()

	@Test
	fun `The lambda passed to toComponents() is executed exactly once`() {
		var executed = false

		SourcePositionOffset(line = 0u, column = 0u).toComponents { _: UInt, _: UInt ->
			@Suppress("KotlinConstantConditions")
			assertFalse(executed)

			executed = true
		}

		@Suppress("KotlinConstantConditions")
		assertTrue(executed)
	}

	@Test
	fun `toComponents() yields the same line and column that were passed to the constructor`() {
		testToComponents(lineOffset = 0, columnOffset = 0)
		testToComponents(lineOffset = 1, columnOffset = 1)
		testToComponents(lineOffset = 8, columnOffset = 4)
	}

	// endregion

	// region String.calculateSourcePositionOffset()

	@Test
	fun `The calculated offset of the empty string is 0 for both line and column offset`() {
		testCalculateOffset(
			expectedLineOffset = 0,
			expectedColumnOffset = 0,
			string = "",
		)
	}

	@Test
	fun `The calculated offset of 'foo' is line offset 0 and column offset 3`() {
		testCalculateOffset(
			expectedLineOffset = 0,
			expectedColumnOffset = 3,
			string = "foo",
		)
	}

	@Test
	fun `The calculated offset of 'foo' + newline + 'bar' is line offset 1 and column offset 3`() {
		testCalculateOffset(
			expectedLineOffset = 1,
			expectedColumnOffset = 3,
			string = "foo\nbar",
		)
	}

	@Test
	fun `The calculated offset of 'foo' + newline is line offset 1 and column offset 0`() {
		testCalculateOffset(
			expectedLineOffset = 1,
			expectedColumnOffset = 0,
			string = "foo\n",
		)
	}

	// endregion

	// region .plus()

	@Test
	fun `Adding the calculated offsets of two empty strings yields 0 for both the line and column offset`() {
		testPlus(
			expectedLineOffset = 0,
			expectedColumnOffset = 0,
			leftString = "",
			rightString = "",
		)
	}

	@Test
	fun `Adding the calculated offsets of 'foo' and 'bar' yields line offset 0 and column offset 6`() {
		testPlus(
			expectedLineOffset = 0,
			expectedColumnOffset = 6,
			leftString = "foo",
			rightString = "bar",
		)
	}

	@Test
	fun `Adding the calculated offsets of 'foo'+newline+'bar' and 'baz' yields line offset 1 and column offset 6`() {
		testPlus(
			expectedLineOffset = 1,
			expectedColumnOffset = 6,
			leftString = "foo\nbar",
			rightString = "baz",
		)
	}

	@Test
	fun `Adding the calculated offsets of 'foo'+newline and 'bar' yields line offset 1 and column offset 3`() {
		testPlus(
			expectedLineOffset = 1,
			expectedColumnOffset = 3,
			leftString = "foo\n",
			rightString = "bar",
		)
	}

	// endregion
}

private fun testToComponents(lineOffset: Int, columnOffset: Int) {
	require(lineOffset >= 0)
	require(columnOffset >= 0)

	SourcePositionOffset(line = lineOffset.toUInt(), column = columnOffset.toUInt())
		.toComponents { actualLine: UInt, actualColumn: UInt ->
			assertEquals(lineOffset.toUInt(), actualLine)
			assertEquals(columnOffset.toUInt(), actualColumn)
		}
}

private fun testCalculateOffset(expectedLineOffset: Int, expectedColumnOffset: Int, string: String) {
	require(expectedLineOffset >= 0)
	require(expectedColumnOffset >= 0)

	string.calculateSourcePositionOffset().toComponents { line: UInt, column: UInt ->
		assertEquals(expectedLineOffset.toUInt(), line)
		assertEquals(expectedColumnOffset.toUInt(), column)
	}
}

private fun testPlus(expectedLineOffset: Int, expectedColumnOffset: Int, leftString: String, rightString: String) {
	require(expectedLineOffset >= 0)
	require(expectedColumnOffset >= 0)

	val resultOffset: SourcePositionOffset = leftString.calculateSourcePositionOffset() +
		rightString.calculateSourcePositionOffset()

	resultOffset.toComponents { line: UInt, column: UInt ->
		assertEquals(expectedLineOffset.toUInt(), line)
		assertEquals(expectedColumnOffset.toUInt(), column)
	}
}
