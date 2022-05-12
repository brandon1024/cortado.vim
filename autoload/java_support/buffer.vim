" Starting at line number `lnum`, find the first line matching pattern `patt`,
" returning the line number. Return 0 if no such line could be found or a buffer
" with the given name could not be found.
function! java_support#buffer#FindLineMatchingPattern(buf, lnum, patt) abort
	let l:idx = a:lnum

	let l:bufinfo = getbufinfo(a:buf)
	if empty(l:bufinfo)
		return 0
	endif

	let l:bufinfo = l:bufinfo[0]

	" older versions of vim don't have 'linecount'
	if has_key(l:bufinfo, 'linecount')
		let l:linecount = l:bufinfo['linecount']
	else
		if empty(l:bufinfo['windows'])
			return 0
		endif

		let l:linecount = line('$', l:bufinfo['windows'][0])
	endif

	while l:idx > 0 && l:idx <= l:linecount
		if match(getbufline(a:buf, l:idx)[0], a:patt) >= 0
			return l:idx
		endif

		let l:idx += 1
	endwhile

	return 0
endfunction

" Starting at line number `lnum`, find and return all lines matching pattern
" `patt`.
function! java_support#buffer#FindLinesMatchingPattern(buf, lnum, patt) abort
	let l:idx = a:lnum
	let l:lines = []
	while l:idx != 0
		let l:idx = java_support#buffer#FindLineMatchingPattern(a:buf, l:idx, a:patt)
		if l:idx
			call extend(l:lines, getbufline(a:buf, l:idx))
			let l:idx += 1
		endif
	endwhile

	return l:lines
endfunction

" Return a list of lines from the current buffer matching pattern `patt`.
" The lines are removed from the buffer.
" Lines are trimmed of leading/trailing whitespace. Duplicate lines are
" removed.
function! java_support#buffer#FilterLinesMatchingPattern(buf, lnum, patt) abort
	let l:lines = []

	let l:lnum = a:lnum
	while l:lnum > 0
		let l:lnum = java_support#buffer#FindLineMatchingPattern(a:buf, l:lnum, a:patt)
		if l:lnum
			call extend(l:lines, getbufline(a:buf, l:lnum))
			call deletebufline(a:buf, l:lnum)
		endif
	endwhile

	return l:lines
endfunction

" Starting from line number `lnum` in the current buffer, remove all lines
" matching the pattern `trunc_patt` until a line matching `stop_patt` is
" encountered.  Return the line number matching `stop_patt`, or 0 if pattern
" not found.
function! java_support#buffer#TruncateToPattern(lnum, trunc_patt, stop_patt) abort
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

" Write out lines from `lines` at line number `lnum` to the current buffer.
" `lines` is flattened before being written.
function! java_support#buffer#WriteLines(lnum, lines) abort
	for line in reverse(java_support#util#Flatten(a:lines))
		call appendbufline('%', a:lnum, line)
	endfor
endfunction

