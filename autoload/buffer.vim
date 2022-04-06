" Starting at line number `lnum`, find the first line matching pattern `patt`,
" returning the line number. Return 0 if no such line could be found.
function! buffer#FindLineMatchingPattern(lnum, patt, buf = '%') abort
	let l:idx = a:lnum
	while l:idx <= line('$')
		if match(getbufline(a:buf, l:idx), a:patt) >= 0
			return l:idx
		endif

		let l:idx += 1
	endwhile

	return 0
endfunction

" Return a list of lines from the current buffer matching pattern `patt`.
" The lines are removed from the buffer.
" Lines are trimmed of leading/trailing whitespace. Duplicate lines are
" removed.
function! buffer#FilterLinesMatchingPattern(patt) abort
	let l:lines = []

	let l:lnum = 1
	while l:lnum > 0
		let l:lnum = buffer#FindLineMatchingPattern(l:lnum, a:patt)
		if l:lnum
			call add(l:lines, getline(l:lnum))
			call deletebufline('%', l:lnum)
		endif
	endwhile

	return l:lines
endfunction

" Starting from line number `lnum`, remove all lines matching the pattern
" `trunc_patt` until a line matching `stop_patt` is encountered.
" Return the line number matching `stop_patt`, or 0 if pattern not found.
function! buffer#TruncateToPattern(lnum, trunc_patt, stop_patt) abort
	let l:idx = a:lnum
	for l in getline(l:idx, line('$'))
		if match(l, a:stop_patt) >= 0
			return l:idx
		endif

		if match(l, a:trunc_patt) >= 0
			call deletebufline('%', a:lnum)
		else
			let a:lnum += 1
		endif
	endfor

	return 0
endfunction

" Write out lines from `lines` at line number `lnum`. `lines` is flattened
" before being written.
function! buffer#WriteLines(lnum, lines) abort
	for line in reverse(flatten(a:lines))
		call appendbufline('%', a:lnum, line)
	endfor
endfunction

