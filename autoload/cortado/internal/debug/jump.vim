" Create a new debug jumper handle.
function! cortado#internal#debug#jump#new() abort
	let l:handle = {}

	let l:handle.jump_to = function('s:jump_to')

	return l:handle
endfunction

" Jump to line `lnum` in class `class`. Returns true of the jump was
" successful, false otherwise.
function! s:jump_to(class, lnum) abort
	return s:jump_to_tag(a:class, a:lnum) ||
		\ s:warn_no_source(a:class, a:lnum)
endfunction

function! s:jump_to_tag(class, lnum) abort
	let l:utils = cortado#internal#util#new()

	if empty(tagfiles())
		" can't jump, no tag files
		return v:false
	endif

	" this won't work with nested classes
	let l:components = split(a:class, '\.')
	let l:package = l:components[0:-2]
	let l:class_name = l:components[-1]

	let l:results = taglist('^' . l:class_name . '$')
		\ ->filter({ idx, result -> result.kind == 'c' && has_key(result, 'filename') })

	if len(l:results) != 1
		" TODO we can check the package statement for each result to try and
		" find the currect one to jump to
		return v:false
	endif

	" show in existing window if already open
	let l:existing_win = bufwinid(bufnr(l:results[0].filename))
	if l:existing_win != -1
		call win_gotoid(l:existing_win)
		call cursor(a:lnum, 0)
		redraw
		return v:true
	endif

	" otherwise, show in the last used, unmodified window
	let l:windows = getbufinfo({ 'buflisted': v:true, 'bufloaded': v:true, 'bufmodified': v:false })
		\ ->sort({ buf1, buf2 -> buf2.lastused - buf1.lastused })
		\ ->map({ idx, buf -> buf.windows })

	" flatten and filter all in the current tabpage
	let l:windows = l:utils.flatten(l:windows)
		\ ->map({ idx, win -> getwininfo(win) })

	let l:windows = l:utils.flatten(l:windows)
		\ ->filter({ idx, wininfo -> wininfo.tabnr == tabpagenr() })
		\ ->map({ idx, wininfo -> wininfo.winid })

	if !empty(l:windows)
		call win_gotoid(l:windows[0])
		execute 'edit ' . l:results[0].filename
		call cursor(a:lnum, 0)
		redraw
		return v:true
	endif

	return v:false
endfunction

function! s:warn_no_source(class, lnum) abort
	let l:utils = cortado#internal#util#new()
	return l:utils.warn('cannot find source for class ' . a:class . ':' . a:lnum)
endfunction

