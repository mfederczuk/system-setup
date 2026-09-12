package io.github.mfederczuk.systemsetupmanager.fs

import io.github.mfederczuk.systemsetupmanager.syntax.patterns.Identifier
import kotlinx.collections.immutable.ImmutableList

data class FsTaskDefinition(
	val identifier: Identifier,
	val actions: ImmutableList<FsTaskAction>,
)
