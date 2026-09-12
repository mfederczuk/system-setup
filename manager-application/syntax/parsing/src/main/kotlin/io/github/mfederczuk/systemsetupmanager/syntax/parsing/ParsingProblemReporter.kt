package io.github.mfederczuk.systemsetupmanager.syntax.parsing

@FunctionalInterface
public fun interface ParsingProblemReporter {

	public fun reportProblem(problem: ParsingProblem)
}
