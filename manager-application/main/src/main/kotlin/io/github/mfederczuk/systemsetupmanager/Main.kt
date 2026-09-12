@file:JvmName("Main")

package io.github.mfederczuk.systemsetupmanager

import io.github.mfederczuk.systemsetupmanager.fs.FsTaskAction
import io.github.mfederczuk.systemsetupmanager.fs.FsTaskDefinition
import io.github.mfederczuk.systemsetupmanager.fs.loadTaskDefinitionsFrom
import io.github.mfederczuk.systemsetupmanager.syntax.lexing.tokenize
import io.github.mfederczuk.systemsetupmanager.syntax.token.Token
import kotlinx.collections.immutable.ImmutableList
import kotlinx.collections.immutable.toImmutableList
import java.nio.file.Path
import kotlin.system.exitProcess

fun main(args: Array<String>) {
	val path = args
		.getOrElse(0) {
			System.err.println("missing argument")
			exitProcess(2)
		}
		.let(Path::of)

	val taskDefinitions: ImmutableList<FsTaskDefinition> = loadTaskDefinitionsFrom(path)

	val x: String = taskDefinitions.single()
		.flattenToCopyActions()
		.joinToString(separator = "\n") { "${it.sourcePath}  =>  ${it.targetPath}" }

	println(x)
}

private fun FsTaskDefinition.flattenToCopyActions(): ImmutableList<FsTaskAction.Copying> {
	return this.actions
		.flatMap { action: FsTaskAction ->
			when (action) {
				is FsTaskAction.Copying -> listOf(action)
				is FsTaskAction.TaskExecution -> action.task.flattenToCopyActions()
			}
		}
		.toImmutableList()
}

private fun readFromStdinAndPrintAnsiColoredToStderr() {
	var requiresTrailingNewline = false

	for (token: Token in System.`in`.bufferedReader().tokenize()) {
		val sourceCode: String = token.toSourceCode()

		System.err.print(token.ansiColorize(sourceCode))

		val tokenHasTrailingNewline: Boolean = (token is Token.Whitespace) && sourceCode.endsWith('\n')
		requiresTrailingNewline = !tokenHasTrailingNewline
	}

	if (requiresTrailingNewline) {
		System.err.println()
	}
}

private fun Token.ansiColorize(string: String): String {
	val colorCode: Int? =
		when (this) {
			is Token.Keyword -> 36
			is Token.Identifier -> 33
			is Token.StringLiteral -> if (this.isTerminated) 35 else 31
			is Token.Brace -> 0
			is Token.DoubleColon -> 0
			is Token.Whitespace -> 0
			is Token.LineComment -> 32
			is Token.Unknown -> 31
		}

	return "\u001b[${colorCode}m${string}\u001b[0m"
}
