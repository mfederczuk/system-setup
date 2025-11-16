/*
 * Copyright (c) 2025 Michael Federczuk
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
				SourcePositionOffset(
					line = thisLine + otherLine,
					column = thisColumn + otherColumn,
				)
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

		public fun String.calculateSourcePositionOffset(): SourcePositionOffset {
			return this@calculateSourcePositionOffset
				.countNewlineCharsAndFindIndexOfLast { newlineCharCount: Int, lastNewlineCharIndex: Int ->
					if (newlineCharCount == 0) {
						SourcePositionOffset(
							line = 0u,
							column = this@calculateSourcePositionOffset.length.toUInt(),
						)
					} else {
						SourcePositionOffset(
							line = newlineCharCount.toUInt(),
							column = (this@calculateSourcePositionOffset.length - lastNewlineCharIndex - 1).toUInt(),
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
