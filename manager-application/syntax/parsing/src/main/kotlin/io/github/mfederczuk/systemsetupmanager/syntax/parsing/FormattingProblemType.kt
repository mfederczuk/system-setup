package io.github.mfederczuk.systemsetupmanager.syntax.parsing

// TODO: these should be part of a formatter
//       formatter should work on the CST?
public enum class FormattingProblemType {

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
