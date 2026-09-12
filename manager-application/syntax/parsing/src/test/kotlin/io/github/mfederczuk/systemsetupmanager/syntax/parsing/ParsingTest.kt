package io.github.mfederczuk.systemsetupmanager.syntax.parsing

import io.github.mfederczuk.systemsetupmanager.sourceposition.SourcePosition
import io.github.mfederczuk.systemsetupmanager.syntax.ast.TaskAction
import io.github.mfederczuk.systemsetupmanager.syntax.ast.TasksModule
import io.github.mfederczuk.systemsetupmanager.syntax.ast.TasksModuleElement
import io.github.mfederczuk.systemsetupmanager.syntax.patterns.Identifier.Companion.toIdentifier
import io.github.mfederczuk.systemsetupmanager.syntax.token.Token
import kotlinx.collections.immutable.persistentListOf
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.fail

private val Space: Token.Whitespace = Token.Whitespace(" ")
private val Newline: Token.Whitespace = Token.Whitespace("\n")
private val Tab: Token.Whitespace = Token.Whitespace("\t")

class ParsingTest {

	@Test
	fun test() {
		val tokens: Sequence<Token> =
			sequenceOf(
				// region import "foo"
				Token.Keyword.Import,
				Space,
				Token.StringLiteral(contents = "foo", isTerminated = true),
				// endregion
				Newline + Newline,
				// region task bar {
				Token.Keyword.Task,
				Space,
				Token.Identifier(unwrapped = "bar".toIdentifier()),
				Space,
				Token.Brace.Open,
				// endregion
				Newline + Tab,
				// region copy "source" to "target"
				Token.Keyword.Copy,
				Space,
				Token.StringLiteral(contents = "source", isTerminated = true),
				Space,
				Token.Keyword.To,
				Space,
				Token.StringLiteral(contents = "target", isTerminated = true),
				// endregion
				Newline + Tab,
				Token.LineComment(commentText = " I'm a comment!"),
				Newline + Tab,
				// region "foo"::baz
				Token.StringLiteral(contents = "foo", isTerminated = true),
				Token.DoubleColon,
				Token.Identifier(unwrapped = "baz".toIdentifier()),
				// endregion
				Newline,
				Token.Brace.Closed,
			)

		val actualTasksModule: TasksModule = tokens.parse { problem: ParsingProblem -> fail(problem.toString()) }

		val expectedTasksModule =
			TasksModule(
				elements = persistentListOf(
					TasksModuleElement.ImportStatement(
						sourcePositionRange = (SourcePosition.Begin)..(1 pos 12),
						string = "foo",
					),
					TasksModuleElement.TaskDefinition(
						sourcePositionRange = (3 pos 1)..(7 pos 1),
						identifier = "bar".toIdentifier(),
						actions = persistentListOf(
							TaskAction.Copying(
								sourcePositionRange = (4 pos 2)..(4 pos 26),
								source = "source",
								target = "target",
							),
							TaskAction.TaskExecution(
								sourcePositionRange = (6 pos 2)..(6 pos 11),
								namespace = "foo",
								taskIdentifier = "baz".toIdentifier(),
							),
						),
					),
				),
			)

		assertEquals(expectedTasksModule, actualTasksModule)
	}
}

private operator fun Token.Whitespace.plus(other: Token.Whitespace): Token.Whitespace {
	return Token.Whitespace(sourceCode = this.toSourceCode() + other.toSourceCode())
}

private infix fun Int.pos(column: Int): SourcePosition {
	require(this >= 0)
	require(column >= 0)

	return SourcePosition(line = this.toUInt(), column = column.toUInt())
}
