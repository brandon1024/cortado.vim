" Create a new sign handle.
function! cortado#internal#sign#new() abort
	let l:handle = {}

	let l:handle.define = function('s:define')
	let l:handle.place = function('s:place')
	let l:handle.remove = function('s:remove')
	let l:handle.remove_all = function('s:remove_all')

	return l:handle
endfunction

" Define a new type of sign. `name` is an arbitrary (but unique) name for this
" sign type. `sign` is the text shown in the sign column. `sign_highlight` is
" the highlight group of the sign text. `line_highlight` is the highlight group
" of the buffer line that the sign is on.
"
" Returns `name`.
function! s:define(name, sign, sign_highlight, line_highlight) abort
	call sign_define(a:name, {
		\ 'text': a:sign,
		\ 'texthl': a:sign_highlight,
		\ 'linehl': a:line_highlight
	\ })
	return a:name
endfunction

" Place a sign on line `lnum` of buffer `buf`. `definition` is the name of the
" sign type (created with s:define()). `group` is an arbitrary group for these
" signs (for easy removal). `priority` is used to determine which sign to show
" when there are multiple signs on the same line.
"
" Returns the unique allocated sign id.
function! s:place(definition, group, buf, lnum, priority) abort
	return sign_place(0, a:group, a:definition, a:buf, {
		\ 'lnum': a:lnum,
		\ 'priority': a:priority
	\ })
endfunction

" Remove a specific sign in group `group` by id.
function! s:remove(group, id) abort
	call sign_unplace(a:group, { 'id': a:id })
endfunction

" Remove all signs in group `group`.
function! s:remove_all(group) abort
	call sign_unplace(a:group)
endfunction

