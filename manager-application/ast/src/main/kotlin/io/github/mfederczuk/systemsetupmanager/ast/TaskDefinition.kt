/*
 * Copyright (c) 2025 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.ast

import kotlinx.collections.immutable.ImmutableList

public data class TaskDefinition(
	public val name: TaskName,
	public val actions: ImmutableList<TaskAction>,
)
