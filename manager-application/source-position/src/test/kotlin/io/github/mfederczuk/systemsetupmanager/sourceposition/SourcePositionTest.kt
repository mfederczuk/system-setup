/*
 * Copyright (c) 2026 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.sourceposition

import org.junit.jupiter.params.ParameterizedTest
import org.junit.jupiter.params.converter.ConvertWith
import org.junit.jupiter.params.converter.SimpleArgumentConverter
import org.junit.jupiter.params.provider.FieldSource
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertTrue

class SourcePositionTest {

	companion {

		val sourcePositions: List<SourcePosition> =
			listOf(
				SourcePosition.Begin,
				SourcePosition(line = 1u, column = 3u),
				SourcePosition(line = 2u, column = 1u),
				SourcePosition(line = 4u, column = 6u),
			)
	}

	// region toComponents()

	@Test
	fun `The lambda passed to the function toComponents() is executed exactly once`() {
		var executed = false

		SourcePosition(line = 1u, column = 1u).toComponents { _: UInt, _: UInt ->
			@Suppress("KotlinConstantConditions")
			assertFalse(executed)

			executed = true
		}

		@Suppress("KotlinConstantConditions")
		assertTrue(executed)
	}

	@Test
	fun `The function toComponents() yields the same line and column that were passed to the constructor`() {
		fun test(line: Int, column: Int) {
			require(line > 0)
			require(column > 0)

			val line: UInt = line.toUInt()
			val column: UInt = column.toUInt()

			SourcePosition(line, column).toComponents { actualLine: UInt, actualColumn: UInt ->
				assertEquals(line, actualLine)
				assertEquals(column, actualColumn)
			}
		}

		test(line = 1, column = 1)
		test(line = 2, column = 2)
		test(line = 8, column = 4)
	}

	// endregion

	// region plus()

	// TODO: name
	@ParameterizedTest
	@FieldSource("sourcePositions")
	fun foo(@ConvertWith(SourcePositionToLongConverter::class) position: SourcePosition) {
		assertEquals(position, position + "")
	}

	// TODO: name
	@ParameterizedTest
	@FieldSource("sourcePositions")
	fun bar(@ConvertWith(SourcePositionToLongConverter::class) position: SourcePosition) {
		val expected: SourcePosition =
			position.toComponents { line: UInt, column: UInt ->
				SourcePosition(line, column = column + 6u)
			}

		assertEquals(expected, position + "foobar")
	}

	// TODO: name
	@ParameterizedTest
	@FieldSource("sourcePositions")
	fun baz(@ConvertWith(SourcePositionToLongConverter::class) position: SourcePosition) {
		val expected: SourcePosition =
			position.toComponents { line: UInt, _: UInt ->
				SourcePosition(line = line + 1u, column = 4u)
			}

		assertEquals(expected, position + "foo\nbar")
	}

	// TODO: name
	@ParameterizedTest
	@FieldSource("sourcePositions")
	fun yee(@ConvertWith(SourcePositionToLongConverter::class) position: SourcePosition) {
		val expected: SourcePosition =
			position.toComponents { line: UInt, _: UInt ->
				SourcePosition(line = line + 1u, column = 1u)
			}

		assertEquals(expected, position + "foo\n")
	}

	// endregion

	// region String.sourcePositionRange()
	// endregion
}

private class SourcePositionToLongConverter : SimpleArgumentConverter() {

	override fun convert(source: Any?, targetType: Class<*>): Any {
		assertEquals(Long::class.java, targetType)
		assertIs<SourcePosition>(source)
		return source.lineAndColumn.toLong()
	}
}
