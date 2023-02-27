# shellcheck shell=sh
# -*- sh -*-
# vim: syntax=sh
# code: language=shellscript

umask 022

if [ -n "${HOME-}" ] && [ -f "$HOME/.environment.sh" ]; then
	# shellcheck source=shell/environment.sh
	. "$HOME/.environment.sh"
elif [ -f ~'/.environment.sh' ]; then
	# shellcheck source=shell/environment.sh
	. ~'/.environment.sh'
elif [ -f '.environment.sh' ]; then
	# shellcheck source=shell/environment.sh
	. '.environment.sh'
fi

#region shell specific runcoms

if [ -n "$BASH_VERSION" ]; then
	if [ -f "$HOME/.bashrc" ]; then
		# shellcheck source=shell/shells/bash/rc.bash
		. "$HOME/.bashrc"
	fi
fi

if [ -n "$ZSH_VERSION" ]; then
	if [ -f "$HOME/.zshrc" ]; then
		# shellcheck disable=1091
		. "$HOME/.zshrc"
	fi
fi

if [ -n "$FISH_VERSION" ]; then
	if [ -f "$HOME/.fishrc" ]; then
		# shellcheck disable=1091
		. "$HOME/.fishrc"
	fi
fi

#endregion

#region cleaning up environment variable PATH

# squeezing colons
if \command printf '%s' "$PATH" | \command grep -Eq '::'; then
	PATH="$({ \command printf '%s' "$PATH" | \command tr -s ':'; } && \command printf x)"
	PATH="${PATH%x}"
fi

# removing optional leading & trailing colons
PATH="${PATH#:}"
PATH="${PATH%:}"

export PATH

#endregion
