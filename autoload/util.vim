" Return true if `ident` is a valid Java identifier (package) component.
function! util#IsValidJavaIdentifierComponent(ident) abort
	if !len(a:ident)
		return v:false
	endif

	" See Java SE Spec, section 3.8
	return match(a:ident, '^[a-zA-Z$_][a-zA-Z0-9$_]*$') >= 0
endfunction

" Flatten a list. This exists because the built-in flatten() function is
" pretty new and not well supported yet.
" This should behave like flattennew(), except that negative numbers indicate
" no max depth limit, and the function only accepts lists.
function! util#Flatten(list, maxdepth = -1) abort
	if a:maxdepth == 0
		return a:list
	endif

	let l:result = []
	for curr in a:list
		if type(curr) == v:t_list
			call extend(l:result, util#Flatten(curr, max([a:maxdepth - 1, -1])))
		else
			call add(l:result, curr)
		endif
	endfor

	return l:result
endfunction

" Reduce a list by predicate. This exists because the built-in reduce()
" function is pretty new and not well supported yet.
" This should behave list reduce(), except the original list is not modified,
" and only lists are supported.
function! util#Reduce(list, func, ...) abort
	if !len(a:list) && !a:0
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

