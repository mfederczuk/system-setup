#!/bin/bash
# -*- sh -*-
# vim: set syntax=sh
# code: language=shellscript

# Copyright (c) 2023 Michael Federczuk
# SPDX-License-Identifier: MPL-2.0 AND Apache-2.0

# TODO: rewrite

argv0() {
	if [ "$(realpath -- "$0")" = "$0" ]; then
		printf -- %s "$(basename -- "$0")"
	else
		printf -- %s "$0"
	fi
}

if (($# > 0)); then
	echo "$(argv0): too many arguments: $#" >&2
	echo "usage: $(argv0)" >&2
	exit 3
fi

declare -a branches=()

while read -rs line; do
	# skip the branch that is currently checked out
	if [ "${line:0:1}" = '*' ]; then
		continue
	fi

	# only take branches were the tracked upstream branch is gone
	if [[ "$line" =~ ^([^[:space:]]+)[[:space:]]+[a-f0-9]+' ['[^[:space:]]+': gone]' ]]; then
		branches+=("${BASH_REMATCH[1]}")
	fi
done < <(git -P branch --list -vv || exit)

if ((${#branches[@]} == 0)); then
	echo "No branches to delete" >&2
	exit
fi

declare -i failedc=0 i
declare branch

for ((i = 0; i < ${#branches[@]}; ++i)); do
	branch="${branches[i]}"

	if ((i > 0)); then
		echo >&2
	fi

	read -rp "Delete '$branch'? [Y/n] " answer || continue
	case "$answer" in
		'Y'*|'y'*|'') ;;
		*)
			# don't delete this branch - continue to next one
			continue
			;;
	esac

	# requested to delete branch

	if git -P branch -d "$branch"; then
		# successfully deleted branch
		continue
	fi

	# failed to delete branch

	if ! git -P diff --quiet --exit-code "$branch" HEAD; then
		# difference between branch and HEAD
		((++failedc))
		continue
	fi

	# no difference between branch and HEAD

	echo >&2 || continue
	echo "There are no changes between '$branch' and HEAD." >&2 || continue
	read -rp "Force delete '$branch'? [Y/n] " answer || continue
	case "$answer" in
		'Y'*|'y'*|'') ;;
		*)
			# don't force delete this branch - continue to next one
			continue
			;;
	esac

	git -P branch -D "$branch" ||
		((++failedc))
done

case $failedc in
	0) ;; # no branches failed to be deleted - success
	"${#branches[@]}") exit 49 ;; # all branches failed to be deleted
	*) exit 48 ;; # some branches failed to be deleted
esac
