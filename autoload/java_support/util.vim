" Flatten a list. This exists because the built-in flatten() function is
" pretty new and not well supported yet.
" This should behave like flattennew(), except that negative numbers indicate
" no max depth limit, and the function only accepts lists.
function! java_support#util#Flatten(list, maxdepth = -1) abort
	if a:maxdepth == 0
		return a:list
	endif

	let l:result = []
	for curr in a:list
		if type(curr) == v:t_list
			call extend(l:result, java_support#util#Flatten(curr, max([a:maxdepth - 1, -1])))
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
function! java_support#util#Reduce(list, func, ...) abort
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

" Traverse the directory tree, starting from `path`. Invokes the lambda
" `callback` for each file found.
"
" This function respects `wildignore` and will filter any file that matches
" a pattern defined.
"
" Callback accepts only a single argument, the path of the file found.
function! java_support#util#TraverseDirs(path, callback) abort
	let l:path = [a:path]
	let l:stack = []

	while !empty(l:path)
		if len(l:path) > len(l:stack)
			" if we stepped into a directory
			let l:dir = readdirex(join(l:path, '/'), 1, { 'sort': 'none' })
			call add(l:stack, l:dir)
		else
			" otherwise restore where we were from the stack
			let l:dir = l:stack[-1]
		end

		" if we were finished processing, pop and continue
		if empty(l:dir)
			let l:stack = l:stack[0:-2]
			let l:path = l:path[0:-2]
		endif

		" work backwords, removing entries as they are processed
		for idx in reverse(range(len(l:dir)))
			let l:dir_entry = remove(l:dir, idx)

			if l:dir_entry.type == 'file'
				let l:file_path = join(java_support#util#Flatten([l:path, l:dir_entry.name]), '/')

				call s:InvokeUnlessIgnored(l:file_path, a:callback)
			elseif l:dir_entry.type == 'dir'
				call add(l:path, l:dir_entry.name)
				break
			endif
		endfor
	endwhile
endfunction

" Invoke the given callback if the file is not `wildignore`d.
function! s:InvokeUnlessIgnored(file_path, callback)
	for ignore_patt in split(&wildignore, ',')
		if match(a:file_path, glob2regpat(ignore_patt)) >= 0
			return
		endif
	endfor

	call a:callback(a:file_path)
endfunction

