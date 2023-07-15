# shellcheck shell=bash
# -*- sh -*-
# vim: syntax=bash
# code: language=shellscript

# SPDX-License-Identifier: CC0-1.0

#region Bash builtins

alias dirs='dirs -v'
alias jobs='jobs -l'
alias time='command time' # suppress using Bash's built-in `time` command

#endregion

function __bash_aliases__is_program_gnu() {
	local binary_name="$1" || return
	local canonical_program_name="$2" || return
	local package_name="$3" || return

	if ! command -v "$binary_name" > '/dev/null'; then
		return 32
	fi

	local program_version_info || return
	program_version_info="$(command "$binary_name" --version 2> '/dev/null')" || return 33

	if [[ ! "$program_version_info" =~ ^"$canonical_program_name (GNU $package_name)" ]]; then
		return 34
	fi

	return 0
}

function __bash_aliases__is_program_gnu_coreutils() {
	__bash_aliases__is_program_gnu "$1" "$1" 'coreutils'
}

#region POSIX utilities

if __bash_aliases__is_program_gnu_coreutils ls; then
	alias ls='ls -l       --human-readable --classify --color=auto --group-directories-first'
	alias la='ls -l --all --human-readable --classify --color=auto --group-directories-first'
else
	alias ls='ls -laF'
	alias la='ls -lF'
fi

#region creating/renaming/deleting file & directory utilities

if [ "$(id -u)" != '0' ]; then
	# non-root user

	if __bash_aliases__is_program_gnu_coreutils cp; then
		alias cp='cp --verbose'
	fi

	if __bash_aliases__is_program_gnu_coreutils mv; then
		alias mv='mv --verbose'
	fi

	if __bash_aliases__is_program_gnu_coreutils rm; then
		alias rm='rm --verbose'
	fi
else
	# root user

	if __bash_aliases__is_program_gnu_coreutils cp; then
		alias cp='cp --verbose --interactive'
	else
		alias cp='cp -i'
	fi

	if __bash_aliases__is_program_gnu_coreutils mv; then
		alias mv='mv --verbose --interactive'
	else
		alias mv='mv -i'
	fi

	if __bash_aliases__is_program_gnu_coreutils rm; then
		alias rm='rm --verbose --interactive=always'
	else
		alias rm='rm -i'
	fi
fi

if __bash_aliases__is_program_gnu_coreutils mkdir; then
	alias mkdir='mkdir --verbose --parents'
else
	alias mkdir='mkdir -p'
fi

if __bash_aliases__is_program_gnu_coreutils rmdir; then
	alias rmdir='rmdir --verbose'
fi

#endregion

#region permission utilities

if __bash_aliases__is_program_gnu_coreutils chmod; then
	alias chmod='chmod --verbose --preserve-root'
fi

if __bash_aliases__is_program_gnu_coreutils chown; then
	alias chown='chown --verbose --preserve-root'
fi

if __bash_aliases__is_program_gnu_coreutils chgrp; then
	alias chgrp='chgrp --verbose --preserve-root'
fi

#endregion

#region grep

if __bash_aliases__is_program_gnu grep 'grep' 'grep'; then
	alias grep='grep --color=auto'
fi

if __bash_aliases__is_program_gnu egrep 'grep' 'grep'; then
	alias egrep='egrep --color=auto'
fi

if __bash_aliases__is_program_gnu fgrep 'grep' 'grep'; then
	alias fgrep='fgrep --color=auto'
fi

#endregion

if __bash_aliases__is_program_gnu diff 'diff' 'diffutils'; then
	alias diff='diff --color=auto'
fi

if __bash_aliases__is_program_gnu_coreutils df; then
	alias df='df --human-readable --total'
else
	# for some reason, GNU df's -t option is --type instead of --total
	alias df='df -kt'
fi

if __bash_aliases__is_program_gnu_coreutils du; then
	alias du='du --bytes --total --human-readable'
fi

#endregion

# BASE: prefixing system's native package manager command with root command

#region Git

if command -v git > '/dev/null'; then
	function __bash_aliases__exists_git_command() {
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


	if __bash_aliases__exists_git_command addall; then
		alias addall='git addall'
	fi

	if __bash_aliases__exists_git_command adduv; then
		alias adduv='git adduv'
	fi

	if __bash_aliases__exists_git_command branchall; then
		alias branchall='git branchall'
	fi

	if __bash_aliases__exists_git_command graph; then
		alias graph='git graph'
	fi

	if __bash_aliases__exists_git_command stat; then
		alias gstat='git stat'
	fi


	unset -f __bash_aliases__exists_git_command
fi

#endregion

#region GNU tar

if __bash_aliases__is_program_gnu tar 'tar' 'tar'; then
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

declare -a __bash_aliases__c_cxx_compiler_cmds
__bash_aliases__c_cxx_compiler_cmds=(
	cc c++
	gcc g++
	clang clang++
)

declare -a __bash_aliases__c_cxx_compiler_args
__bash_aliases__c_cxx_compiler_args=(
	-Wall -Wextra
	-Wconversion -Werror=infinite-recursion
	-pedantic -Wpedantic -pedantic-errors -Werror=pedantic
)

declare __bash_aliases__c_cxx_compiler_args_str

#region joining args into one string

__bash_aliases__c_cxx_compiler_args_str=''

declare __bash_aliases__c_cxx_compiler_arg

for __bash_aliases__c_cxx_compiler_arg in "${__bash_aliases__c_cxx_compiler_args[@]}"; do
	if [ -n "$__bash_aliases__c_cxx_compiler_args_str" ]; then
		__bash_aliases__c_cxx_compiler_args_str+=' '
	fi

	__bash_aliases__c_cxx_compiler_args_str+="$__bash_aliases__c_cxx_compiler_arg"
done

unset -v __bash_aliases__c_cxx_compiler_arg

#endregion

unset -v __bash_aliases__c_cxx_compiler_args

#region creating the aliases

declare __bash_aliases__c_cxx_compiler_cmd

for __bash_aliases__c_cxx_compiler_cmd in "${__bash_aliases__c_cxx_compiler_cmds[@]}"; do
	if ! command -v "$__bash_aliases__c_cxx_compiler_cmd" > '/dev/null'; then
		continue
	fi

	# shellcheck disable=2139
	alias "$__bash_aliases__c_cxx_compiler_cmd"="$__bash_aliases__c_cxx_compiler_cmd $__bash_aliases__c_cxx_compiler_args_str"
done

unset -v __bash_aliases__c_cxx_compiler_cmd

#endregion

unset -v __bash_aliases__c_cxx_compiler_args_str \
         __bash_aliases__c_cxx_compiler_cmds

#endregion

#region VLC

if command -v vlc > '/dev/null'; then
	alias vlc-no-one-instance='vlc --no-one-instance'
	alias vlc-one-instance-playlist-enqueue='vlc --one-instance --playlist-enqueue'
fi

#endregion

#region 7z

# for some reason there are like 3 different 7z commands and different Linux distros use only some of these commands

declare __bash_aliases__7z_cmd

for __bash_aliases__7z_cmd in 7z 7za 7zr; do
	if ! command -v $__bash_aliases__7z_cmd > '/dev/null'; then
		continue
	fi

	# shellcheck disable=2139
	alias "$__bash_aliases__7z_cmd-ultra"="$__bash_aliases__7z_cmd -t7z -m0=lzma -mx=9 -mfb=64 -md=32m -ms=on"
done

unset -v __bash_aliases__7z_cmd

#endregion

#region other

if command -v vim > '/dev/null'; then
	# -n  ->  no swap file, use memory only
	# -p  ->  open one tab page for each file
	alias vim='vim -np'
fi

if command -v less > '/dev/null'; then
	# -+X  ->  enable termcap initialization/deinitialization
	alias less='less --quit-if-one-screen --ignore-case --LONG-PROMPT --LINE-NUMBERS --RAW-CONTROL-CHARS --chop-long-lines -+X'
fi

if command -v tree > '/dev/null'; then
	# -I <pattern>  ->  ignore <pattern>
	# -F            ->  same as ls's -F/--classify
	alias tree='tree -I .git -I node_modules -F --dirsfirst'
fi

if __bash_aliases__is_program_gnu_coreutils shred; then
	# -u  ->  remove file after shredding
	alias shred='shred -u --verbose --zero'
fi

if command -v youtube-dl > '/dev/null'; then
	alias youtube-dl-to-mp3="youtube-dl --format=bestaudio -x --audio-format=mp3 --audio-quality=0 --prefer-ffmpeg -o '%(title)s.%(ext)s'"
fi

if command -v gzip > '/dev/null'; then
	alias gzip='gzip --verbose'
fi

if command -v xz > '/dev/null'; then
	alias xz='xz --verbose'
fi

if command -v free > '/dev/null'; then
	alias free='free -h'
fi

if command -v valgrind > '/dev/null'; then
	alias valgrind='valgrind --leak-check=full --show-leak-kinds=all --track-origins=yes'
fi

if command -v dos2unix > '/dev/null'; then
	alias dos2unix='dos2unix --keepdate'
fi

if command -v update-alternatives > '/dev/null'; then
	alias update-alternatives-local='update-alternatives --altdir ~/.local/etc/alternatives --admindir ~/.local/var/lib/alternatives'
fi

if command -v ktlint > '/dev/null'; then
	alias ktlint='ktlint --relative'
fi

if command -v mocp > '/dev/null'; then
	alias mocp='mocp --theme=transparent-background'
fi

#endregion

unset -f __bash_aliases__is_program_gnu_coreutils \
         __bash_aliases__is_program_gnu
