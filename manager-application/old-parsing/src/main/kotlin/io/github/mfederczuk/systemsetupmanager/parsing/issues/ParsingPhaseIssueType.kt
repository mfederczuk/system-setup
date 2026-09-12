/*
 * Copyright (c) 2025 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.parsing.old.issues

import io.github.mfederczuk.systemsetupmanager.token.Token

public sealed interface ParsingPhaseIssueType

// region syntax issues

public enum class SingleTokenSyntaxErrorType : ParsingPhaseIssueType {
	/**
	 * Reported when a token is encountered that is not defined in the grammar.
	 * Corresponds directly to [Token.Unknown].
	 *
	 * ## Examples ##
	 *
	 * ```txt
	 * &
	 * ```
	 */
	UnknownToken,

	/**
	 * Reported when a quoted string ([Token.StringLiteral]) is not terminated.
	 *
	 * ## Examples ##
	 *
	 * ```txt
	 * "foo
	 * ```
	 *
	 * Quoted strings may not span multiple lines, so this following example has *two* cases of an unterminated string:
	 *
	 * ```txt
	 * "foo
	 * bar"
	 * ```
	 *
	 * @see Token.StringLiteral.isTerminated
	 */
	UnterminatedQuotedString,
}

public enum class MultiTokenSyntaxErrorType : ParsingPhaseIssueType {
	/**
	 * Reported when a (valid!) token is encountered where it isn't expected.
	 *
	 * ## Examples ##
	 *
	 * ```txt
	 * import {
	 * ```
	 *
	 * ```txt
	 * task ::
	 * ```
	 */
	UnexpectedToken,
}

public enum class MultiTokenSyntaxWarningType : ParsingPhaseIssueType {
	/**
	 * Reported when there is no whitespace between an `import` keyword and its quoted string.
	 *
	 * ## Examples ##
	 *
	 * ```txt
	 * import"foo"
	 * ```
	 */
	NoWhitespaceBetweenImportKeywordAndQuotedString,

	/**
	 * Reported when a line comment token is directly after a non-whitespace token, making it somewhat ambiguous whether
	 * it actually counts as a comment.
	 *
	 * ## Examples ##
	 *
	 * ```txt
	 * "quoted string"# comment
	 * ```
	 *
	 * ```txt
	 * word# comment
	 * ```
	 *
	 * ```txt
	 * {# comment
	 * ```
	 */
	LineCommentDirectlyAfterNonWhitespace,
}

// endregion

// region static semantic issues

public enum class StaticSemanticErrorType : ParsingPhaseIssueType {
	/**
	 * Reported when an import's value is empty.
	 *
	 * ## Examples ##
	 *
	 * ```txt
	 * import ""
	 * ```
	 */
	EmptyImport,
}

public enum class StaticSemanticWarningType : ParsingPhaseIssueType {
	/**
	 * Reported when an import statement is placed anywhere after the first task definition.
	 *
	 * ## Examples ##
	 *
	 * ```txt
	 * task foo {}
	 *
	 * import "bar"
	 * ```
	 */
	ImportStatementAfterTaskDefinition,

	/**
	 * Reported when the same import appears multiple times in the same tasks unit.
	 *
	 * ## Examples ##
	 *
	 * ```txt
	 * import "foo"
	 * import "foo"
	 * ```
	 */
	DuplicateImport,
}

// endregion
