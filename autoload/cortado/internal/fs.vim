" Create a new fs handle.
function! cortado#internal#fs#new() abort
	let l:handle = {}

	let l:handle.walk_dir = function('s:walk_dir')
	let l:handle.pretty_path = function('s:pretty_path')
	let l:handle.touch = function('s:touch')

	return l:handle
endfunction

" Traverse the directory tree, starting from `path`. Invokes the lambda
" `callback` for each file found.
"
" This function respects `wildignore` and will filter any file that matches
" a pattern defined.
"
" Callback accepts only a single argument, the path of the file found.
"
" No guarantees are made to the order of directory traversal. This is entirely
" system dependent.
function! s:walk_dir(path, callback) abort
	let l:utils = cortado#internal#util#new()

	let l:path = [a:path]
	let l:stack = []

	while !empty(l:path)
		if len(l:path) > len(l:stack)
			" if we stepped into a directory
			let l:dir = readdir(join(l:path, '/'), 1)
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

			let l:dir_entry_path = join(l:utils.flatten([l:path, l:dir_entry]), '/')
			if isdirectory(l:dir_entry_path)
				call add(l:path, l:dir_entry)
				break
			endif

			call s:invoke_unless_ignored(l:dir_entry_path, a:callback)
		endfor
	endwhile
endfunction

" Invoke the given callback if the file is not `wildignore`d.
function! s:invoke_unless_ignored(file_path, callback)
	for ignore_patt in split(&wildignore, ',')
		if match(a:file_path, glob2regpat(ignore_patt)) >= 0
			return
		endif
	endfor

	call a:callback(a:file_path)
endfunction

" An implementation of slice(), which is not widely available yet.
function! s:slice(string, start, end) abort
	return a:string[a:start:a:end-1]
endfunction

" Pretty print a file path. The file name and file path are truncated if they
" are longer than maxlen.
function! s:pretty_path(file, maxlen) abort
	let l:file_relative = fnamemodify(a:file, ':.')
	
	let l:fpath = fnamemodify(l:file_relative, ':h') . '/'
	let l:fname = fnamemodify(l:file_relative, ':t')

	" truncate filename to at most `maxlen` characters, appending '...' if
	" truncated
	let l:trunc_fname = s:slice(s:slice(l:fname, 0, a:maxlen - 3) . '...', 0,
		\ min([a:maxlen, len(l:fname)]))

	" truncate file path to fill remaining space, appending '...' if truncated
	let l:remaining = a:maxlen - len(l:trunc_fname)
	let l:trunc_fpath = s:slice(s:slice(l:fpath, 0, l:remaining - 3) . '...', 0,
		\ min([l:remaining, len(l:fpath)]))

	return l:trunc_fpath . l:trunc_fname
endfunction

" Create the `file`, if one does not already exist.
function! s:touch(file) abort
	let l:utils = cortado#internal#util#new()

	let l:dirname = fnamemodify(a:file, ':p:h')
	if !mkdir(l:dirname, 'p')
		return l:utils.warn('failed to touch file "' . a:file . '"')
	endif

	call writefile([], a:file, 'a')
endfunction

