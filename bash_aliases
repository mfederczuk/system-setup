# shellcheck shell=bash
# -*- sh -*-
# vim: syntax=sh
# code: language=shellscript

# SPDX-License-Identifier: CC0-1.0

#region Bash builtins

alias dirs='dirs -v'
alias time='command time' # suppress using Bash's built-in `time` command

#endregion

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

#region POSIX utilities

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

if __dotfiles_bash_aliases__is_program_gnu diff 'diffutils'; then
	alias diff='diff --color=auto'
fi

if __dotfiles_bash_aliases__is_program_gnu_coreutils df; then
	alias df='df --human-readable --total'
else
	# for some reason, GNU df's -t option is --type instead of --total
	alias df='df -kt'
fi

unset -v __dotfiles_bash_aliases__is_program_gnu_coreutils

#endregion

#region Git

if command -v git > '/dev/null'; then
	function __dotfiles_bash_aliases__exists_git_command() {
		local command_name || return
		command_name="$1" || return
		readonly command_name || return

		#region checking aliases

		if git --no-pager config --get --system alias."$command_name" > '/dev/null'; then
			return 0
		fi

		if git --no-pager config --get --global alias."$command_name" > '/dev/null'; then
			return 0
		fi

		#endregion

		# checking custom commands
		if command -v "git-$command_name" > '/dev/null'; then
			return 0
		fi

		# checking official commands
		if git --no-pager help "$command_name" &> '/dev/null' < '/dev/null'; then
			return 0
		fi

		return 32
	}


	if __dotfiles_bash_aliases__exists_git_command addall; then
		alias addall='git addall'
	fi

	if __dotfiles_bash_aliases__exists_git_command adduv; then
		alias adduv='git adduv'
	fi

	if __dotfiles_bash_aliases__exists_git_command branchall; then
		alias branchall='git branchall'
	fi

	if __dotfiles_bash_aliases__exists_git_command graph; then
		alias graph='git graph'
	fi

	if __dotfiles_bash_aliases__exists_git_command stat; then
		alias gstat='git stat'
	fi


	unset -v __dotfiles_bash_aliases__exists_git_command
fi

#endregion

#region GNU tar

if __dotfiles_bash_aliases__is_program_gnu tar 'tar'; then
	alias tar.gz='tar --gzip'
	alias tar.xz='tar --xz'
	alias tar.zstd='tar --zstd'

	alias untar='tar --extract'
	alias untar.gz='tar --extract --gzip'
	alias untar.xz='tar --extract --xz'
	alias untar.zstd='tar --extract --zstd'
fi

#endregion

#region C & C++ compiler

declare -a __dotfiles_bash_aliases__c_cxx_compiler_cmds
__dotfiles_bash_aliases__c_cxx_compiler_cmds=(
	cc c++
	gcc g++
	clang clang++
)

declare -a __dotfiles_bash_aliases__c_cxx_compiler_args
__dotfiles_bash_aliases__c_cxx_compiler_args=(
	-Wall -Wextra
	-Wconversion -Werror=infinite-recursion
	-pedantic -Wpedantic -pedantic-errors -Werror=pedantic
)

declare __dotfiles_bash_aliases__c_cxx_compiler_args_str

#region joining args into one string

__dotfiles_bash_aliases__c_cxx_compiler_args_str=''

declare __dotfiles_bash_aliases__c_cxx_compiler_arg

for __dotfiles_bash_aliases__c_cxx_compiler_arg in "${__dotfiles_bash_aliases__c_cxx_compiler_args[@]}"; do
	if [ -n "$__dotfiles_bash_aliases__c_cxx_compiler_args_str" ]; then
		__dotfiles_bash_aliases__c_cxx_compiler_args_str+=' '
	fi

	__dotfiles_bash_aliases__c_cxx_compiler_args_str+="$__dotfiles_bash_aliases__c_cxx_compiler_arg"
done

unset -v __dotfiles_bash_aliases__c_cxx_compiler_arg

#endregion

unset -v __dotfiles_bash_aliases__c_cxx_compiler_args

#region creating the aliases

declare __dotfiles_bash_aliases__c_cxx_compiler_cmd

for __dotfiles_bash_aliases__c_cxx_compiler_cmd in "${__dotfiles_bash_aliases__c_cxx_compiler_cmds[@]}"; do
	if ! command -v "$__dotfiles_bash_aliases__c_cxx_compiler_cmd" > '/dev/null'; then
		continue
	fi

	# shellcheck disable=2139
	alias "$__dotfiles_bash_aliases__c_cxx_compiler_cmd"="$__dotfiles_bash_aliases__c_cxx_compiler_cmd $__dotfiles_bash_aliases__c_cxx_compiler_args_str"
done

unset -v __dotfiles_bash_aliases__c_cxx_compiler_cmd

#endregion

unset -v __dotfiles_bash_aliases__c_cxx_compiler_args_str \
         __dotfiles_bash_aliases__c_cxx_compiler_cmds

#endregion

#region VLC

if command -v vlc > '/dev/null'; then
	alias vlc-no-one-instance='vlc --no-one-instance'
	alias vlc-one-instance-playlist-enqueue='vlc --one-instance --playlist-enqueue'
fi

#endregion

#region 7z

# for some reason there are like 3 different 7z commands and different Linux distros use only some of these commands

declare __dotfiles_bash_aliases__7z_cmd

for __dotfiles_bash_aliases__7z_cmd in 7z 7za 7zr; do
	if ! command -v $__dotfiles_bash_aliases__7z_cmd > '/dev/null'; then
		continue
	fi

	# shellcheck disable=2139
	alias "$__dotfiles_bash_aliases__7z_cmd-ultra"="$__dotfiles_bash_aliases__7z_cmd -t7z -m0=lzma -mx=9 -mfb=64 -md=32m -ms=on"
done

unset -v __dotfiles_bash_aliases__7z_cmd

#endregion

unset -v __dotfiles_bash_aliases__is_program_gnu
