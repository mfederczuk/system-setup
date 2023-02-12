" SPDX-License-Identifier: CC0-1.0

" line numbers
set number

" mouse support
set mouse=a

set modeline
set modelines=5

" smart home key
" i found this sometime, somewhere online, but don't remember where and also can't find this exact snippet anymore
" god fucking knows how this shit works, because i sure as hell don't
noremap <expr> <silent> <Home> col('.') == match(getline('.'),'\S')+1 ? '0' : '^'
imap <silent> <Home> <C-O><Home>
