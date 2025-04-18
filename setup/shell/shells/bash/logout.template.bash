# shellcheck shell=bash
# -*- sh -*-
# vim: syntax=bash
# code: language=shellscript

# SPDX-License-Identifier: CC0-1.0

#%% if (bashLogoutClearConsole) {
if [ "$SHLVL" = 1 ]; then
	if [ -x '/usr/bin/clear_console' ]; then
		/usr/bin/clear_console -q
	fi
fi
#%% }
