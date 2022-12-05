" Create a new progress handle.
function! cortado#internal#progress#new() abort
	let l:handle = {}

	let l:handle.show = function('s:show')
	let l:handle.update = function('s:update')
	let l:handle.complete = function('s:complete')

	return l:handle
endfunction

" Display a popup to report progress information. Returns a handle to the popup.
function! s:show(message) abort
	if g:cortado_progress_disabled
		return v:null
	endif

	let l:popups = cortado#internal#popup#new()

	let l:popup = l:popups.status_message(' ' . a:message . ' ')
	redraw

	return l:popup
endfunction

" Update the progress popup text. Optionally accepts `file`, the name of the
" file currently being processed.
function! s:update(popup_id, message, file = '') abort
	if g:cortado_progress_disabled || a:popup_id == v:null
		return
	endif

	let l:fs = cortado#internal#fs#new()

	" calculate max length of message (3 included for whitespace)
	let l:maxlen = 80 - len(a:message) - 3
	call popup_settext(a:popup_id, ' ' . a:message . ' ' .
		\ (len(a:file) ? l:fs.pretty_path(a:file, l:maxlen) . ' ' : ''))

	redraw
endfunction

" Show a completion message and close the progress popup after a 1 second
" delay.
function! s:complete(popup_id, message) abort
	if g:cortado_progress_disabled || a:popup_id == v:null
		return
	endif

	call popup_settext(a:popup_id, ' ' . a:message . ' ')
	redraw

	function! s:close_popup(timer_id) abort closure
		call popup_close(a:popup_id)
	endfunction

	call timer_start(1000, function('s:close_popup'))
endfunction

