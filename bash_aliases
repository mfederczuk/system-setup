# shellcheck shell=bash
# -*- sh -*-
# vim: syntax=sh
# code: language=shellscript

alias dirs='dirs -v'

function __dotfiles_bash_aliases__is_program_gnu() {
	local program_name="$1" || return
	local package_name="$2" || return

	if ! command -v "$program_name" > '/dev/null'; then
		return 32
	fi

	local program_version_info || return
	program_version_info="$(command "$program_name" --version)" || return 33

	if [[ ! "$program_version_info" =~ ^"$program_name (GNU $package_name)" ]]; then
		return 34
	fi

	return 0
}

#region coreutils

function __dotfiles_bash_aliases__is_program_gnu_coreutils() {
	__dotfiles_bash_aliases__is_program_gnu "$1" 'coreutils'
}

if __dotfiles_bash_aliases__is_program_gnu_coreutils ls; then
	alias ls='ls -l       --human-readable --classify --color=auto --group-directories-first'
	alias la='ls -l --all --human-readable --classify --color=auto --group-directories-first'
else
	alias ls='ls -laF'
	alias la='ls -lF'
fi

#region creating/renaming/deleting file & directory utilities

if [ "$(id -u)" != '0' ]; then
	# non-root user

	if __dotfiles_bash_aliases__is_program_gnu_coreutils cp; then
		alias cp='cp --verbose'
	fi

	if __dotfiles_bash_aliases__is_program_gnu_coreutils mv; then
		alias mv='mv --verbose'
	fi

	if __dotfiles_bash_aliases__is_program_gnu_coreutils rm; then
		alias rm='rm --verbose'
	fi
else
	# root user

	if __dotfiles_bash_aliases__is_program_gnu_coreutils cp; then
		alias cp='cp --verbose --interactive'
	else
		alias cp='cp -i'
	fi

	if __dotfiles_bash_aliases__is_program_gnu_coreutils mv; then
		alias mv='mv --verbose --interactive'
	else
		alias mv='mv -i'
	fi

	if __dotfiles_bash_aliases__is_program_gnu_coreutils rm; then
		alias rm='rm --verbose --interactive=always'
	else
		alias rm='rm -i'
	fi
fi

if __dotfiles_bash_aliases__is_program_gnu_coreutils mkdir; then
	alias mkdir='mkdir --verbose --parents'
else
	alias mkdir='mkdir -p'
fi

if __dotfiles_bash_aliases__is_program_gnu_coreutils rmdir; then
	alias rmdir='rmdir --parents'
else
	alias rmdir='rmdir -p'
fi

#endregion

#region permission utilities

if __dotfiles_bash_aliases__is_program_gnu_coreutils chmod; then
	alias chmod='chmod --verbose --preserve-root'
fi

if __dotfiles_bash_aliases__is_program_gnu_coreutils chown; then
	alias chown='chown --verbose --preserve-root'
fi

#endregion

if __dotfiles_bash_aliases__is_program_gnu_coreutils df; then
	alias df='df --human-readable --total'
else
	# for some reason, GNU df's -t option is --type instead of --total
	alias df='df -kt'
fi

unset -v __dotfiles_bash_aliases__is_program_gnu_coreutils

#endregion

if __dotfiles_bash_aliases__is_program_gnu tar 'tar'; then
	alias tar.gz='tar --gzip'
	alias tar.xz='tar --xz'
	alias tar.zstd='tar --zstd'

	alias untar='tar --extract'
	alias untar.gz='tar --extract --gzip'
	alias untar.xz='tar --extract --xz'
	alias untar.zstd='tar --extract --zstd'
fi

unset -v __dotfiles_bash_aliases__is_program_gnu
