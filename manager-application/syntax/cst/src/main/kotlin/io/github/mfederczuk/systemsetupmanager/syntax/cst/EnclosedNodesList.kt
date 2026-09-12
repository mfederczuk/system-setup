/*
 * Copyright (c) 2025 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.syntax.cst

import io.github.mfederczuk.systemsetupmanager.sourceposition.SourcePosition
import io.github.mfederczuk.systemsetupmanager.syntax.token.Token
import kotlinx.collections.immutable.ImmutableList
import kotlinx.collections.immutable.PersistentList
import kotlinx.collections.immutable.persistentListOf
import kotlinx.collections.immutable.plus
import kotlinx.collections.immutable.toImmutableList
import kotlinx.collections.immutable.toPersistentList

@ConsistentCopyVisibility
public data class EnclosedNodesList<N : Node> private constructor(
	private val elements: ImmutableList<Element<N>>,
) : Node() {

	private sealed class Element<out N : Node> {

		data class Node<N : io.github.mfederczuk.systemsetupmanager.syntax.cst.Node>(val unwrapped: N) : Element<N>()

		data class NonNode(val tokens: ImmutableList<Token>) : Element<Nothing>()
	}

	public class Builder<N : Node> {

		private val elements: PersistentList.Builder<Element<N>> = persistentListOf<Element<N>>().builder()

		public fun addNode(node: N) {
			this.elements += Element.Node(node)
		}

		public fun addNonNode(tokens: ImmutableList<Token>) {
			if (tokens.isEmpty()) {
				return
			}

			when (val lastElement: Element<N>? = this.elements.lastOrNull()) {
				null, is Element.Node -> {
					this.elements += Element.NonNode(tokens)
				}

				is Element.NonNode -> {
					this.elements[this.elements.lastIndex] = lastElement
						.copy(tokens = lastElement.tokens.toPersistentList() + tokens)
				}
			}
		}

		public fun build(): EnclosedNodesList<N> {
			return EnclosedNodesList(elements = this.elements.build())
		}
	}

	public fun filterNodesWithPosition(begin: SourcePosition = SourcePosition.Begin): Sequence<Pair<SourcePosition, N>> {
		return sequence {
			var position: SourcePosition = begin

			for (element: Element<N> in this@EnclosedNodesList.elements) {
				when (element) {
					is Element.Node -> {
						yield(position to element.unwrapped)
						position += element.unwrapped.toSourceCode()
					}

					is Element.NonNode -> {
						for (token: Token in element.tokens) {
							position += token.toSourceCode()
						}
					}
				}
			}
		}
	}

	public fun filterNodes(): ImmutableList<N> {
		return this.elements
			.mapNotNull { element: Element<N> ->
				when (element) {
					is Element.Node -> element.unwrapped
					is Element.NonNode -> null
				}
			}
			.toImmutableList()
	}

	override fun combineTokens(): ImmutableList<Token> {
		return this.elements
			.flatMap { element: Element<N> ->
				when (element) {
					is Element.Node -> element.unwrapped.combineTokens()
					is Element.NonNode -> element.tokens
				}
			}
			.toImmutableList()
	}
}
