/*
 * Copyright (c) 2026 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.sourceposition

import io.github.mfederczuk.systemsetupmanager.sourceposition.SourcePositionOffset.Companion.calculateSourcePositionOffset
import kotlin.contracts.ExperimentalContracts
import kotlin.contracts.InvocationKind
import kotlin.contracts.contract

@JvmInline
public value class SourcePosition private constructor(private val lineAndColumn: ULong) : Comparable<SourcePosition> {

	public constructor(line: UInt, column: UInt) : this(lineAndColumn = (line.toULong() shl 32) or column.toULong()) {
		require(line != 0u)
		require(column != 0u)
	}

	public operator fun plus(offset: SourcePositionOffset): SourcePosition {
		return this.toComponents { line: UInt, column: UInt ->
			offset.toComponents { lineOffset: UInt, columnOffset: UInt ->
				if (lineOffset == 0u) {
					SourcePosition(
						line = line,
						column = column + columnOffset,
					)
				} else {
					SourcePosition(
						line = line + lineOffset,
						column = 1u + columnOffset,
					)
				}
			}
		}
	}

	public fun rangeOf(string: String): OpenEndRange<SourcePosition> {
		return this..<(this + string.calculateSourcePositionOffset())
	}

	public fun calculateOffsetFromBegin(): SourcePositionOffset {
		return this.toComponents { thisLine: UInt, thisColumn: UInt ->
			SourcePositionOffset(line = thisLine - 1u, column = thisColumn - 1u)
		}
	}

	override fun compareTo(other: SourcePosition): Int {
		return this.lineAndColumn.compareTo(other.lineAndColumn)
	}

	override fun toString(): String {
		return this.toComponents { line: UInt, column: UInt ->
			"$line:$column"
		}
	}

	@OptIn(ExperimentalContracts::class)
	private inline fun <R> toComponents(action: (line: UInt, column: UInt) -> R): R {
		contract {
			callsInPlace(action, InvocationKind.EXACTLY_ONCE)
		}

		val line: UInt = (this.lineAndColumn shr 32).toUInt()
		val column: UInt = this.lineAndColumn.toUInt()
		return action(line, column)
	}

	public companion object {

		public val Begin: SourcePosition = SourcePosition(line = 1u, column = 1u)

		public fun String.sourcePositionRange(begin: SourcePosition = Begin): OpenEndRange<SourcePosition> {
			return begin..<(begin + this.calculateSourcePositionOffset())
		}
	}
}
