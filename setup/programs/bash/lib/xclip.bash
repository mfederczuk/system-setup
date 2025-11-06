# SPDX-License-Identifier: CC0-1.0

if ! command -v xclip > '/dev/null'; then
	return
fi

function __dotfiles_bash_funcs_xclip__print_replaced_error() {
	if command -v termfx > '/dev/null'; then
		{
			termfx color.red && printf 'Replaced with `' &&
				termfx font.weight.bold && printf '%s' "$1" && termfx reset &&
				termfx color.red && printf '`.' && termfx reset &&
				printf '\n'
		} >&2
	else
		printf "Replaced with \`%s\`.\\n" "$1" >&2
	fi

	return 127
}

function xcopystr() {
	__dotfiles_bash_funcs_xclip__print_replaced_error 'clipboard copy <text>'
}

function xcopyfile() {
	__dotfiles_bash_funcs_xclip__print_replaced_error 'clipboard copy [ < <file> ]'
}

function xpaste() {
	__dotfiles_bash_funcs_xclip__print_replaced_error 'clipboard paste'
}

function xclip-clear() {
	__dotfiles_bash_funcs_xclip__print_replaced_error 'clipboard clear'
}

function xclip-sort() {
	__dotfiles_bash_funcs_xclip__print_replaced_error 'clipboard paste | sort [<args>...] | clipboard copy'
}
