// SPDX-License-Identifier: CC0-1.0

package io.github.mfederczuk.systemsetupmanager.utils

public fun String.quoted(): String {
	return '"' +
		this
			.replace("\\", "\\\\")
			.replace("\"", "\\\"") +
		'"'
}
