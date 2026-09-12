/*
 * Copyright (c) 2026 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.sourceposition

import kotlin.contracts.ExperimentalContracts
import kotlin.contracts.InvocationKind
import kotlin.contracts.contract

// TODO: rename to `StringPosition` or `TextPosition`?

@JvmInline
public value class SourcePosition internal constructor(
	@PublishedApi internal val lineAndColumn: ULong,
) : Comparable<SourcePosition> {

	public constructor(line: UInt, column: UInt) : this(lineAndColumn = (line.toULong() shl 32) or column.toULong()) {
		require(line != 0u)
		require(column != 0u)
	}

	@OptIn(ExperimentalContracts::class)
	public inline fun <R> toComponents(action: (line: UInt, column: UInt) -> R): R {
		contract {
			callsInPlace(action, InvocationKind.EXACTLY_ONCE)
		}

		val line: UInt = (this.lineAndColumn shr 32).toUInt()
		val column: UInt = this.lineAndColumn.toUInt()
		return action(line, column)
	}

	public operator fun plus(source: String): SourcePosition {
		return this.toComponents { thisLine: UInt, thisColumn: UInt ->
			source.countNewlineCharsAndFindIndexOfLast { sourceNewlineCharCount: Int, sourceLastNewlineCharIndex: Int ->
				if (sourceNewlineCharCount == 0) {
					SourcePosition(
						line = thisLine,
						column = thisColumn + source.length.toUInt(),
					)
				} else {
					SourcePosition(
						line = thisLine + sourceNewlineCharCount.toUInt(),
						column = (source.length - sourceLastNewlineCharIndex).toUInt(),
					)
				}
			}
		}
	}

	public operator fun rangeTo(endInclusive: SourcePosition): SourcePositionRange.NonEmpty {
		return SourcePositionRange.NonEmpty(
			start = this,
			endInclusive = endInclusive,
		)
	}

	override fun compareTo(other: SourcePosition): Int {
		return this.lineAndColumn.compareTo(other.lineAndColumn)
	}

	override fun toString(): String {
		return this.toComponents { line: UInt, column: UInt ->
			"$line:$column"
		}
	}

	public companion object {

		public val Begin: SourcePosition = SourcePosition(line = 1u, column = 1u)

		public fun String.sourcePositionRange(start: SourcePosition = Begin): SourcePositionRange {
			if (this.isEmpty()) {
				return SourcePositionRange.Empty(start = start)
			}

			return this.countNewlineCharsAndFindIndexOfLast { newlineCharCount: Int, lastNewlineCharIndex: Int ->
				val endInclusive: SourcePosition =
					start.toComponents { line: UInt, column: UInt ->
						if (newlineCharCount == 0) {
							SourcePosition(
								line = line,
								column = column + (this.length - 1).toUInt(),
							)
						} else {
							SourcePosition(
								line = line + newlineCharCount.toUInt(),
								column = (this.length - lastNewlineCharIndex - 1).toUInt(),
							)
						}
					}

				start..endInclusive
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
