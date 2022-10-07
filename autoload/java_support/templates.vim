" Insert a local variable declartion and assignment on the current line.
function! java_support#templates#InsertLocalVariable() abort
	if &filetype != 'java'
		return java_support#util#Warn('cannot insert variable declaration: unexpected filetype "' . &filetype . '"')
	endif

	let l:lnum = line('.')
	let l:ltext = getline(l:lnum)

	" find index of first non-whitespace character, or zero if no whitespace
	let l:start = max([match(l:ltext, '\w'), 0])

	" prepend with 'final'
	let l:declr = g:java_insert_var_declare_final ? 'final ' : ''

	" insert declaration at start of line
	let l:before_cursor = l:ltext[:l:start - 1] . l:declr . 'var '
	let l:after_cursor = ' = ' . l:ltext[l:start:]

	call setline(l:lnum, l:before_cursor . l:after_cursor)
	call cursor(l:lnum, len(l:before_cursor) + 1)
endfunction

