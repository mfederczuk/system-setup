/*
 * Copyright (c) 2026 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.sourceposition

import kotlin.contracts.ExperimentalContracts
import kotlin.contracts.InvocationKind
import kotlin.contracts.contract

@JvmInline
public value class SourcePositionOffset private constructor(private val lineAndColumn: ULong) {

	internal constructor(line: UInt, column: UInt) : this(lineAndColumn = (line.toULong() shl 32) or column.toULong())

	public operator fun plus(other: SourcePositionOffset): SourcePositionOffset {
		return this.toComponents { thisLine: UInt, thisColumn: UInt ->
			other.toComponents { otherLine: UInt, otherColumn: UInt ->
				if (otherLine == 0u) {
					SourcePositionOffset(
						line = thisLine,
						column = thisColumn + otherColumn,
					)
				} else {
					SourcePositionOffset(
						line = thisLine + otherLine,
						column = otherColumn,
					)
				}
			}
		}
	}

	override fun toString(): String {
		return this.toComponents { line: UInt, column: UInt ->
			"SourcePositionOffset(line = $line, column = $column)"
		}
	}

	@OptIn(ExperimentalContracts::class)
	internal inline fun <R> toComponents(action: (line: UInt, column: UInt) -> R): R {
		contract {
			callsInPlace(action, InvocationKind.EXACTLY_ONCE)
		}

		val line: UInt = (this.lineAndColumn shr 32).toUInt()
		val column: UInt = this.lineAndColumn.toUInt()
		return action(line, column)
	}

	public companion object {

		public val Zero: SourcePositionOffset = SourcePositionOffset(lineAndColumn = 0uL)

		public fun String.calculateSourcePositionOffset(): SourcePositionOffset {
			return this.countNewlineCharsAndFindIndexOfLast { newlineCharCount: Int, lastNewlineCharIndex: Int ->
				if (newlineCharCount == 0) {
					SourcePositionOffset(
						line = 0u,
						column = this.length.toUInt(),
					)
				} else {
					SourcePositionOffset(
						line = newlineCharCount.toUInt(),
						column = (this.length - lastNewlineCharIndex - 1).toUInt(),
					)
				}
			}
		}
	}
}

@OptIn(ExperimentalContracts::class)
private inline fun <R> String.countNewlineCharsAndFindIndexOfLast(action: (count: Int, lastIndex: Int) -> R): R {
	contract {
		callsInPlace(action, InvocationKind.EXACTLY_ONCE)
	}

	var count = 0
	var latestIndex = -1

	this.forEachIndexed { index: Int, char: Char ->
		if (char != '\n') {
			return@forEachIndexed
		}

		++count
		latestIndex = index
	}

	return action(count, latestIndex)
}
