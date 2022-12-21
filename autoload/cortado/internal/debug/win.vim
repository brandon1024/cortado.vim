" Create a new debug window handle.
function! cortado#internal#debug#win#new() abort
	let l:handle = {}

	let l:handle.open = function('s:open')

	return l:handle
endfunction

" Open and configure a new window that will show the debugger terminal.
" Returns the window id.
function! s:open() abort
	bo 16new

	" configure window
	let l:winnr = winnr('$')
	call setwinvar(l:winnr, '&number', 0)
	call setwinvar(l:winnr, '&relativenumber', 0)

	return win_getid()
endfunction

