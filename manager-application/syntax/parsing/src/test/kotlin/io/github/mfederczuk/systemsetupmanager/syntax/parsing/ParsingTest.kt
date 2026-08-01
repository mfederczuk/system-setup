package io.github.mfederczuk.systemsetupmanager.syntax.parsing

import io.github.mfederczuk.systemsetupmanager.syntax.ast.TaskAction
import io.github.mfederczuk.systemsetupmanager.syntax.ast.TasksModule
import io.github.mfederczuk.systemsetupmanager.syntax.ast.TasksModuleElement
import io.github.mfederczuk.systemsetupmanager.syntax.patterns.Identifier.Companion.toIdentifier
import io.github.mfederczuk.systemsetupmanager.syntax.token.Token
import kotlinx.collections.immutable.persistentListOf
import kotlin.test.Test
import kotlin.test.assertEquals

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

		val actualTasksModule: TasksModule = tokens.parse()

		val expectedTasksModule =
			TasksModule(
				elements = persistentListOf(
					TasksModuleElement.ImportStatement(string = "foo"),
					TasksModuleElement.TaskDefinition(
						identifier = "bar".toIdentifier(),
						actions = persistentListOf(
							TaskAction.Copying(source = "source", target = "target"),
							TaskAction.TaskExecution(namespace = "foo", taskIdentifier = "baz".toIdentifier()),
						),
					),
				),
			)

		assertEquals(expectedTasksModule, actualTasksModule)

		println(actualTasksModule)
	}
}

private operator fun Token.Whitespace.plus(other: Token.Whitespace): Token.Whitespace {
	return Token.Whitespace(sourceCode = this.toSourceCode() + other.toSourceCode())
}
