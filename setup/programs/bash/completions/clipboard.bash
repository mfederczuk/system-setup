# SPDX-License-Identifier: CC0-1.0

if ! command -v clipboard > '/dev/null'; then
	return
fi

function _clipboard() {
	declare -ga COMPREPLY
	COMPREPLY=()

	case $COMP_CWORD in
		(0) ;;
		(1)
			# shellcheck disable=SC2034
			mapfile -t COMPREPLY < <(compgen -W 'copy clear paste' -- "${COMP_WORDS[1]-}")
			;;
		(2)
			case "${COMP_WORDS[1]-}" in
				('copy')
					compopt -o bashdefault

					if [[ "${COMP_WORDS[2]-}" == '' ]]; then
						COMPREPLY=('<')
					fi
					;;
				('paste')
					if [[ "${COMP_WORDS[2]-}" == '' ]]; then
						COMPREPLY=('>')
					fi
					;;
			esac
			;;
		(3)
			case "${COMP_WORDS[1]-} ${COMP_WORDS[2]-}" in
				('copy <')
					compopt -o bashdefault -o default -o filenames
					;;
				('paste >')
					compopt -o bashdefault -o default -o filenames
					;;
			esac
			;;
	esac
}

complete -F _clipboard clipboard
