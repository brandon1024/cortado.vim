" Return true if `ident` is a valid Java identifier (package) component.
function! java_support#java#IsValidIdentifier(ident) abort
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
function! java_support#java#NormalizeImportStatements(stmts) abort
	let l:result = []

	for stmt in split(a:stmts, ';')
		let l:stmt = trim(substitute(stmt, '\s\+', ' ', 'g'))
		if empty(l:stmt)
			continue
		endif

		let l:normalized_stmt = s:NormalizeImportStatement(l:stmt)
		if !empty(l:normalized_stmt)
			call add(l:result, l:normalized_stmt)
		endif
	endfor

	return l:result
endfunction

" Normalize a single import statement.
function! s:NormalizeImportStatement(stmt) abort
	let l:matches = matchlist(a:stmt,
		\ '^import\s\+\(static\)\?\(.*\)$')
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

