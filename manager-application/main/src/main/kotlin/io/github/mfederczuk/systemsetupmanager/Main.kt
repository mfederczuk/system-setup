@file:JvmName("Main")

package io.github.mfederczuk.systemsetupmanager

import io.github.mfederczuk.systemsetupmanager.lexing.tokenize
import io.github.mfederczuk.systemsetupmanager.parsing.parse
import io.github.mfederczuk.systemsetupmanager.semanticanalyzes.semanticallyAnalyze
import io.github.mfederczuk.systemsetupmanager.token.Token

fun main() {
	val tasksModule = System.`in`.bufferedReader()
		.tokenize()
		.parse()
		.semanticallyAnalyze()

	System.err.println(tasksModule)
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
			is Token.Identifier -> this.validate(ifLegal = { 33 }, ifIllegal = { 31 })
			is Token.StringLiteral -> if (this.isTerminated) 35 else 31
			is Token.Brace -> 0
			is Token.DoubleColon -> 0
			is Token.Whitespace -> 0
			is Token.LineComment -> 32
			is Token.Unknown -> 31
		}

	return "\u001b[${colorCode}m${string}\u001b[0m"
}
