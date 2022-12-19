" Create a new java handle.
function! cortado#internal#java#new() abort
	let l:handle = {}

	let l:handle.is_valid_identifier = function('s:is_valid_identifier')
	let l:handle.normalize_import_statements = function('s:normalize_import_statements')
	let l:handle.get_package = function('s:get_package')
	let l:handle.get_package_lnum = function('s:get_package_lnum')
	let l:handle.get_package_for_file = function('s:get_package_for_file')

	return l:handle
endfunction

" Return true if `ident` is a valid Java identifier (package) component.
function! s:is_valid_identifier(ident) abort
	if empty(a:ident)
		return v:false
	endif

	" See Java SE Spec, section 3.8
	return match(a:ident, '^[a-zA-Z$_][a-zA-Z0-9$_]*$') >= 0
endfunction

" Build and return a normalized list of import statements from string `stmts`.
"
" The result will be a list of tuples [components, meta], with the following
" format:
" 	[[['ca', 'example', 'package', 'MyClass'], { 's': v:true }], ...]
"
" `components` is the fully-qualified import. `meta` is metadata for the
" import, which has the key 's' indicating whether it's a static import or not.
function! s:normalize_import_statements(stmts) abort
	let l:result = []

	for stmt in split(a:stmts, ';')
		let l:stmt = trim(substitute(stmt, '\s\+', ' ', 'g'))
		if empty(l:stmt)
			continue
		endif

		let l:normalized_stmt = s:normalize_import_statement(l:stmt)
		if !empty(l:normalized_stmt)
			call add(l:result, l:normalized_stmt)
		endif
	endfor

	return l:result
endfunction

" Read the package declaration for a given buffer.
"
" If found, returns the package statement components. Otherwise returns an
" empty list.
function! s:get_package(buffer = '%') abort
	let l:buffers = cortado#internal#buffer#new()

	let l:pkg_stmt_lnum = s:get_package_lnum(a:buffer)
	if l:pkg_stmt_lnum <= 0
		return []
	endif

	let l:pkg_line = getline(l:pkg_stmt_lnum)
	let l:matches = matchlist(l:pkg_line, s:get_package_pattern())
	return split(substitute(l:matches[1], '\s', '', 'g'), '\.')
endfunction

function! s:get_package_lnum(buffer = '%') abort
	let l:buffers = cortado#internal#buffer#new()

	return l:buffers.lnum_matching_patt(a:buffer, 1, s:get_package_pattern())
endfunction

" Read the contents of `file` and look for a package statement.
"
" Loading the entire file into memory can be pretty wasteful, given that
" package statements usually appear very close to the top of the file. To
" reduce overhead, files are read incrementally. In the worst case, this could
" result in multiple file reads, but in the normal case will improve overall
" performance.
"
" If found, returns the package statement components. Otherwise returns an
" empty list.
function! s:get_package_for_file(file) abort
	let l:chunk = 10
	let l:offset = 0

	while v:true
		let l:lines = readfile(a:file, '', l:chunk)

		for line in l:lines[l:offset:-1]
			let l:matches = matchlist(line, s:get_package_pattern())

			if !empty(l:matches)
				return split(substitute(l:matches[1], '\s', '', 'g'), '\.')
			endif
		endfor

		" if we have reached end of file
		if len(l:lines) < l:chunk
			return []
		endif

		let l:offset = len(l:lines)
		let l:chunk *= 3
	endwhile

	return []
endfunction

" Return a pattern that can be used to match package statements.
function! s:get_package_pattern() abort
	return 'package\s\+\([^;]\+\);'
endfunction

" Return a pattern that can be used to match package statements.
function! s:get_import_pattern() abort
	return '^import\s\+\(static\)\?\(.*\)$'
endfunction

" Normalize a single import statement.
function! s:normalize_import_statement(stmt) abort
	let l:matches = matchlist(a:stmt, s:get_import_pattern())
	if len(l:matches) < 3
		return []
	endif

	let l:matched = l:matches[0]
	let l:is_static = len(l:matches[1])
	let l:fq_import = split(substitute(l:matches[2], '\s', '', 'g'), '\.')

	if empty(l:matched) || empty(l:fq_import)
		return []
	endif

	return [l:fq_import, { 's': l:is_static ? v:true : v:false }]
endfunction

