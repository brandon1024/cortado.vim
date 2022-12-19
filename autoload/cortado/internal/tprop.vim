" Create a new text prop handle.
function! cortado#internal#tprop#new() abort
	let l:handle = {}

	let l:handle.insert_shaded = function('s:insert_shaded')

	return l:handle
endfunction

" Highlight line `lnum` in buffer `buffer`.
function! s:insert_shaded(buffer, lnum) abort
	let l:prop_type = 'cortado#internal#tprop#shaded'
	if empty(prop_type_get(l:prop_type, { 'bufnr': a:buffer }))
		call prop_type_add(l:prop_type, {
			\ 'highlight': hlexists('Comment') ? 'Comment' : 'NonText',
			\ 'bufnr': a:buffer,
		\ })
	endif

	call prop_add(a:lnum, 1, {
		\ 'length': strlen(getbufline(a:buffer, a:lnum)[0]),
		\ 'bufnr': a:buffer,
		\ 'type': l:prop_type
	\ })
endfunction

