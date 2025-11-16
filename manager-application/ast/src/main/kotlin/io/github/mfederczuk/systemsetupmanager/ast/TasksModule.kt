/*
 * Copyright (c) 2025 Michael Federczuk
 * SPDX-License-Identifier: MPL-2.0 AND Apache-2.0
 */

package io.github.mfederczuk.systemsetupmanager.ast

import kotlinx.collections.immutable.ImmutableList
import kotlinx.collections.immutable.ImmutableSet

public data class TasksModule(
	public val importStrings: ImmutableSet<ImportString>,
	public val taskDefinitions: ImmutableList<TaskDefinition>,
)
