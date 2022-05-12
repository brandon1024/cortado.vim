" Display a popup to report indexing progress. Returns a handle to the popup.
function! java_support#progress#Show() abort
	if !g:java_import_index_progress
		return v:null
	endif

	let l:popup_id = popup_create(' indexing.. ', {
		\ 'pos': 'botright',
		\ 'line': &lines,
		\ 'col': &columns,
		\ 'maxwidth': 80,
		\ 'minwidth': 80
		\ })
	redraw
	return l:popup_id
endfunction

" Update the progress popup when indexing. Accepts `file`, the name of the
" file currently being indexed.
function! java_support#progress#Update(popup_id, message, file = '') abort
	if !g:java_import_index_progress || a:popup_id == v:null
		return
	endif

	" calculate max length of message (3 included for whitespace)
	let l:maxlen = 80 - len(a:message) - 3
	call popup_settext(a:popup_id, ' ' . a:message . ' ' .
		\ (len(a:file) ? s:PrettyPrintPath(a:file, l:maxlen) . ' ' : ''))

	redraw
endfunction

" Show a completion message and close the progress popup after a 1 second
" delay.
function! java_support#progress#Complete(popup_id, message) abort
	if !g:java_import_index_progress || a:popup_id == v:null
		return
	endif

	call popup_settext(a:popup_id, ' ' . a:message . ' ')
	redraw

	function! s:ClosePopup(timer_id) abort closure
		call popup_close(a:popup_id)
	endfunction

	call timer_start(1000, function('s:ClosePopup'))
endfunction

" Pretty print a file path. The file name and file path are truncated if they
" are longer than maxlen.
function! s:PrettyPrintPath(file, maxlen) abort
	let l:file_relative = fnamemodify(a:file, ':.')
	
	" try to show the filename in full, truncating the path if necessary
	let l:fname = fnamemodify(l:file_relative, ':t')
	let l:fpath = fnamemodify(l:file_relative, ':h') . '/'

	" truncate filename to at most `maxlen` characters, appending '...' if
	" truncated
	let l:trunc_fname = slice(slice(l:fname, 0, a:maxlen - 3) . '...', 0, min([a:maxlen, len(l:fname)]))

	" truncate file path to fill remaining space, appending '...' if truncated
	let l:remaining = a:maxlen - len(l:trunc_fname)
	let l:trunc_fpath = slice(slice(l:fpath, 0, l:remaining - 3) . '...', 0, l:remaining)

	return l:trunc_fpath . l:trunc_fname
endfunction

