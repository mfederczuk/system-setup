package io.github.mfederczuk.systemsetupmanager

import io.github.mfederczuk.systemsetupmanager.fs.FsTaskAction
import io.github.mfederczuk.systemsetupmanager.fs.FsTaskDefinition
import io.github.mfederczuk.systemsetupmanager.fs.TemplatedPath
import kotlinx.collections.immutable.ImmutableList
import java.nio.file.Path

// This was just made as an exercise, it won't actually be used.

// language=sh
private val INTRO: String =
	$$"""
	#!/bin/sh
	# -*- sh -*-
	# vim: syntax=sh
	# code: language=shellscript

	#region preamble

	case "$-" in
	    (*'i'*)
	        \command printf 'script was called interactively\n' 1>&2;
	        return 124;
	        ;;
	esac;

	set -o errexit;
	set -o nounset;

	# enabling POSIX-compliant behavior for GNU programs
	export POSIXLY_CORRECT=yes POSIX_ME_HARDER=yes;

	if [ "${0#/}" = "$0" ]; then
	    argv0="$0";
	else
	    argv0="$(basename -- "$0" && printf x)";
	    argv0="${argv0%"$(printf '\nx')"}";
	fi;
	readonly argv0;

	#endregion

	if [ $# -gt 0 ]; then
	    printf '%s: too many arguments: %i\n' "$argv0" $# 1>&2;
	    exit 2;
	fi;

	home_dir_path="${HOME-}";
	case "$home_dir_path" in
	    ('')
	        # shellcheck disable=SC2016
	        printf '%s: the environment variable $HOME is unset or empty\n' "$argv0" 1>&2
	        exit 1;
	        ;;
	    ('/'*) ;;
	    (*)
	        # shellcheck disable=SC2016
	        printf '%s: the environment variable $HOME is not an absolute path\n' "$argv0" 1>&2
	        exit 1;
	        ;;
	esac;
	readonly home_dir_path;

	config_home_dir_path="${XDG_CONFIG_HOME-}"
	case "$config_home_dir_path" in
	    ('/'*) ;;
	    (*)
	        config_home_dir_path="$home_dir_path/.config";
	        ;;
	esac;
	readonly config_home_dir_path;
	""".trimIndent()

fun FsTaskDefinition.toShellScript(): String {
	return INTRO + "\n\n" +
		this.actions.toShellScript(depth = 0)
}

private fun ImmutableList<FsTaskAction>.toShellScript(depth: Int): String {
	return this
		.joinToString(
			separator = "\n\n",
			transform = { action: FsTaskAction ->
				action.toShellScript(depth)
			},
		)
}

private fun FsTaskAction.toShellScript(depth: Int): String {
	return when (this) {
		is FsTaskAction.Copying -> this.toShellScript()
		is FsTaskAction.TaskExecution -> this.toShellScript(depth)
	}
}

private fun FsTaskAction.Copying.toShellScript(): String {
	val targetRootVarQuoted: String = "\"$" +
		when (this.targetPath.root) {
			TemplatedPath.Root.UserHome -> "home_dir_path"
			TemplatedPath.Root.ConfigHome -> "config_home_dir_path"
		} +
		'"'

	val mkdirArg: String = this.targetPath.relativePath.parent
		?.let { parentPath: Path ->
			"$targetRootVarQuoted/${parentPath.prettyQuoteForShellScript()}"
		}
		?: targetRootVarQuoted

	val cpArg1: String = this.sourcePath.prettyQuoteForShellScript()
	val cpArg2 = "$targetRootVarQuoted/${this.targetPath.relativePath.prettyQuoteForShellScript()}"

	// language=sh
	return """
		mkdir -p -- $mkdirArg;
		cp -- $cpArg1 $cpArg2;
		""".trimIndent()
}

private fun FsTaskAction.TaskExecution.toShellScript(depth: Int): String {
	require(depth >= 0)

	val msg = "${" ".repeat(depth)}> ${this.namespace}::${this.task.identifier}"

	return "printf -- ${msg.prettyQuoteForShellScript()}\\\\n >&2 || true;\n" +
		this.task.actions.toShellScript(depth = depth + 1)
}

private fun Path.prettyQuoteForShellScript(): String {
	return this.toString().prettyQuoteForShellScript()
}

private fun String.prettyQuoteForShellScript(): String {
	return when {
		('!' in this) -> {
			// Exclamation marks can't be properly escaped in double quotation marks.
			// Force single quotation marks and deal with "escaping" single quotation marks.

			('\'' + this.replace("'", "'\\''") + '\'')
				.removePrefix("''")
				.removeSuffix("''")
		}

		('\'' !in this) -> "'$this'"

		else -> {
			'"' +
				this
					.replace("\\", "\\\\")
					.replace("$", "\\$")
					.replace("\"", "\\\"") +
				'"'
		}
	}
}
