" Create a new debug console handle.
function! cortado#internal#debug#job#new() abort
	let l:handle = {}

	let l:handle.new = function('s:new')

	return l:handle
endfunction

function! s:new() abort
	let l:buf = term_start('NONE')

	if !l:buf
		throw 'error: cannot open terminal window'
	endif

	return l:buf
endfunction

