" Create and return list of import statements.
" Each entry in `imports` must have the following format:
" 	^import\s(static\s)?.+
"
" Returns the group of statements. The order of the imports returned is
" undefined.
function! s:CreateImportStatementGroup(imports, packages) abort
	let l:grp = []

	for stmt in a:imports
		" split import statement into parts
		let l:parts = split(stmt)

		" validate
		if !len(l:parts) || len(l:parts) > 3
			echoerr 'bug: unexpected number of parts to statement "' . stmt . '"'
		elseif l:parts[0] != 'import'
			echoerr 'bug: expected import keyword in statement "' . stmt . '"'
		elseif len(l:parts) == 3 && l:parts[1] != 'static'
			echoerr 'bug: malformed statement "' . stmt . '"'
		endif

		" try to match against `packages`
		let l:import_pkg = l:parts[-1]
		for package in a:packages
			if stridx(l:import_pkg, package) == 0
				call add(l:grp, stmt)
				break
			endif
		endfor
	endfor

	return l:grp
endfunction

" Flatten the groups into a single list. If `g:java_import_space_group` is
" true, groups are separated by an empty space.
function! s:FlattenGroups(groups) abort
	call filter(a:groups, { idx, val -> len(val) })

	if g:java_import_space_group
		for idx in range(len(a:groups[0:-2]))
			call add(a:groups[idx], '')
		endfor
	endif

	return util#Flatten(a:groups)
endfunction

function! s:ImportPartitionReducer(acc, val) abort
	call add(a:acc[match(a:val, 'import\sstatic\s.\+;') >= 0], a:val)
	return a:acc
endfunction

" Sort `imports` according to `g:java_import_order`.
function! s:SortImportStatements(imports) abort
	" partition imports into static and non-static
	let l:import_stmts = util#Reduce(a:imports,
		\ function('s:ImportPartitionReducer'), [[],[]])

	" group statements according to configuration
	let l:import_stmt_grps = []
	for group in g:java_import_order
		let l:is_static_group = has_key(group, 'static') && group.static
		let l:grp = s:CreateImportStatementGroup(
			\ l:import_stmts[l:is_static_group ? 1 : 0], group.packages)

		" filter statements
		call filter(l:import_stmts[l:is_static_group ? 1 : 0],
			\ { idx, val -> index(l:grp, val) < 0 })

		call add(l:import_stmt_grps, l:grp)
	endfor

	" second pass for any remaining imports
	for idx in range(len(g:java_import_order))
		let l:group = g:java_import_order[idx]
		let l:is_static_group = has_key(group, 'static') && group.static

		if !len(l:group.packages)
			call extend(l:import_stmt_grps[idx],
				\ l:import_stmts[l:is_static_group ? 1 : 0])
			let l:import_stmts[l:is_static_group ? 1 : 0] = []
		endif
	endfor

	" any statements that don't fit into any group are added to the end
	call add(l:import_stmt_grps, util#Flatten(l:import_stmts))

	" sort groups
	for group in l:import_stmt_grps
		call sort(group)
	endfor

	return s:FlattenGroups(l:import_stmt_grps)
endfunction

" Truncate blank lines starting at line number `lnum`. Return the next
" non-blank line number.
function! s:TruncateBlankLines(lnum)
	return buffer#TruncateToPattern(a:lnum, '^\s*$', '^.')
endfunction

" Sort and write the given import trees `trees` to the current buffer.
" Assumes that all import statements have already been removed from the
" buffer.
function! sort#JavaSortImportsTrees(trees) abort
	" sort import statements according to configuration
	let l:imports = s:SortImportStatements(util#Flatten([
		\ import_tree#Flatten(a:trees['s'], [], 'import static ', ';'),
		\ import_tree#Flatten(a:trees['ns'], [], 'import ', ';')
	\ ]))

	" truncate leading blank lines
	let l:idx = s:TruncateBlankLines(1)

	" look for package statement and truncate empty lines between package
	" statement and first bit of text
	let l:pkg_stmt_lnum = buffer#FindLineMatchingPattern(l:idx, '^\s*package\s.\+;\s*$')
	if l:pkg_stmt_lnum > 0
		call s:TruncateBlankLines(l:pkg_stmt_lnum + 1)
		call buffer#WriteLines(l:pkg_stmt_lnum, ['', l:imports, ''])
	else
		call buffer#WriteLines(0, [l:imports, ''])
	endif
endfunction

" Sort import statements in the current buffer.
function! sort#JavaSortImports() abort
	" ensure this is a java file
	if &filetype != 'java'
		echohl WarningMsg |
			\ echo 'cannot sort imports: unexpected filetype "' . &filetype . '"' |
			\ echohl None
		return
	endif

	call sort#JavaSortImportsTrees(import_tree#Build())
endfunction

