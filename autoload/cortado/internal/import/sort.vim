" Create a new import tree handle.
function! cortado#internal#import#sort#new() abort
	let l:handle = {}

	let l:handle.sort = function('s:sort')
	let l:handle.write = function('s:write')

	return l:handle
endfunction

" Flatten and sort `tree` into a flat list of import statements according
" to `g:cortado_import_order`. `tree` is mutated.
function! s:sort(tree) abort
	let l:java = cortado#internal#java#new()
	let l:utils = cortado#internal#util#new()

	let l:package = l:java.get_package()

	" fill with empty lists
	let l:imports = repeat([[]], len(g:cortado_import_order))

	" first pass, all with 'packages'
	for idx in range(len(g:cortado_import_order))
		let l:group = g:cortado_import_order[idx]

		if !empty(get(l:group, 'packages', []))
			let l:imports[idx] = s:new_group(a:tree, l:package, l:group)
		endif
	endfor

	" second pass, all without 'packages'
	for idx in range(len(g:cortado_import_order))
		let l:group = g:cortado_import_order[idx]

		if empty(get(l:group, 'packages', []))
			let l:imports[idx] = s:new_group(a:tree, l:package, l:group)
		endif
	endfor

	" third pass, any remaining that don't fit in a group
	call add(l:imports, s:new_group(a:tree, l:package,
		\ { 'static': v:true, 'packages': [] }))
	call add(l:imports, s:new_group(a:tree, l:package,
		\ { 'static': v:false, 'packages': [] }))

	return l:utils.flatten(l:imports)
endfunction

" Flatten nodes from `tree` matching specs in `group` into a flat list of
" import statements according to `g:cortado_import_order`. Inserts
" a blank line at the end if `g:cortado_import_space_group` is true.
function! s:new_group(tree, package, group) abort
	let l:statements = s:flatten(a:tree, a:package, a:group)
	if empty(l:statements)
		return []
	endif

	return l:statements + (g:cortado_import_space_group ? [''] : [])
endfunction

" Flatten nodes from `tree` matching specs in `group` into a flat list of
" import statements according to `g:cortado_import_order`.
function! s:flatten(tree, package, group) abort
	let l:trees = cortado#internal#import#tree#new()

	let l:flatten_options = {
		\ 'prefix': 'import ' . (a:group.static ? 'static ' : ''),
		\ 'postfix': ';',
		\ 'filter': {
			\ 's': a:group.static,
			\ 'f': { path, _ -> s:all_predicate(a:package, path) },
			\ 'r': v:true
		\ },
		\ 'sort': v:true
	\ }

	if empty(a:group.packages)
		" flatten all remaining
		return l:trees.flatten(a:tree, l:flatten_options)
	endif

	" flatten for each package prefix
	let l:imports = []
	for prefix in a:group.packages
		let l:flatten_options.filter.f =
			\ { path, _ -> s:with_prefix_predicate(a:package, path, prefix) }
		call add(l:imports, l:trees.flatten(a:tree, l:flatten_options))
	endfor

	return l:imports
endfunction

" Predicate matching any node. If `g:cortado_import_filter_same_package` is
" true, filters nodes in the same `package`.
function! s:all_predicate(package, path) abort
	if !g:cortado_import_filter_same_package
		return v:true
	endif

	return a:package != a:path[0:-2]
endfunction

" Predicate matching any with a path starting with `prefix`. If
" `g:cortado_import_filter_same_package` is true, filters nodes in the same
" `package`.
function! s:with_prefix_predicate(package, path, prefix) abort
	if !s:all_predicate(a:package, a:path)
		return v:false
	endif

	return join(a:path, '.')[0:len(a:prefix) - 1] == a:prefix
endfunction

" Write import `statements` to the current buffer, just below the package
" statement if present.
function! s:write(statements) abort
	let l:java = cortado#internal#java#new()
	let l:buffers = cortado#internal#buffer#new()

	" truncate leading blank lines
	let l:idx = s:truncate_blank_lines(1)

	let l:pkg_stmt_lnum = l:java.get_package_lnum()
	if l:pkg_stmt_lnum > 0
		call s:truncate_blank_lines(l:pkg_stmt_lnum + 1)
		call l:buffers.write(l:pkg_stmt_lnum, ['', a:statements])
	else
		call l:buffers.write(0, ['', a:statements])
	endif
endfunction

" Truncate blank lines starting at line number `lnum`. Return the next
" non-blank line number.
function! s:truncate_blank_lines(lnum) abort
	let l:buffers = cortado#internal#buffer#new()

	return l:buffers.trunc_to_patt(a:lnum, '^\s*$', '^.')
endfunction

