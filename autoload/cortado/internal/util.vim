" Create a new util handle.
function! cortado#internal#util#new() abort
	let l:handle = {}

	let l:handle.flatten = function('s:flatten')
	let l:handle.reduce = function('s:reduce')
	let l:handle.warn = function('s:warn')

	return l:handle
endfunction

" Flatten a list.
"
" This exists because the built-in flatten() function is pretty new and not
" well supported yet. This should behave like flattennew(), except that
" negative numbers indicate no max depth limit, and the function only accepts
" lists.
function! s:flatten(list, maxdepth = -1) abort
	if a:maxdepth == 0
		return a:list
	endif

	let l:result = []
	for curr in a:list
		if type(curr) == v:t_list
			call extend(l:result, s:flatten(curr, max([a:maxdepth - 1, -1])))
		else
			call add(l:result, curr)
		endif
	endfor

	return l:result
endfunction

" Reduce a list by predicate.
"
" This exists because the built-in reduce() function is pretty new and not
" well supported yet. This should behave list reduce(), except the original
" list is not modified, and only lists are supported.
function! s:reduce(list, func, ...) abort
	if empty(a:list) && !a:0
		throw 'bug: list is empty and no initial value provided'
	endif

	if a:0 > 1
		throw 'bug: too many arguments'
	endif

	if !a:0
		let l:acc = a:list[0]
		let l:list = a:list[1:-1]
	else
		let l:list = a:list
		let l:acc = a:1
	endif

	for curr in list
		let l:acc = a:func(l:acc, curr)
	endfor

	return l:acc
endfunction

" Print a warning message.
function! s:warn(message) abort
	echohl WarningMsg |
		\ echo 'cortado.vim: ' . a:message |
		\ echohl None
endfunction

