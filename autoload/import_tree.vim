" Split a fully qualified class name `fq_classname` into its components.
" Returns a list of components.
function! s:SplitQualifiedClassName(fq_classname) abort
	return split(trim(a:fq_classname), '\.')
endfunction

" Split an import statement into individual tokens. The result is a dictionary
" with the following structure:
" 	{ 'static': bool, 'components': List }
"
" Compound statement are not supported. If `stmt` is not a valid import
" statement, expect undefined behaviour.
function! s:TokenizeStatement(stmt) abort
	let l:is_static = v:false

	" replace semicolon with space to split properly, and split into components
	let l:components = split(substitute(a:stmt, ';', ' ', ''))
	if l:components[0] != 'import'
		echoerr 'unexpected statement "' . a:stmt . '"'
	endif

	" is it a static import?
	let l:components = l:components[1:-1]
	if l:components[0] == 'static'
		let l:is_static = v:true
		let l:components = l:components[1:-1]
	endif

	return {
		\ 'static': l:is_static,
		\ 'components': s:SplitQualifiedClassName(l:components[0])
		\ }
endfunction

" Merge `stmt` into `tree`. `stmt` must have the form:
" 	{ 'static': bool, 'components': List }
"
" Returns `tree`, which will have the format:
" 	{ 'root': { 'child1': {...}, 'child2': {...} }, 'leaf': {} }
function! s:MergeImportStatement(tree, stmt) abort
	" check if static or non-static import
	let l:root = a:tree.ns
	if a:stmt.static
		let l:root = tree.s
	endif

	for idx in range(len(a:stmt.components))
		let l:component = a:stmt.components[idx]
		let l:remaining = a:stmt.components[idx+1:-1]

		if l:component == '*'
			" wildcard import are allowed, but must be last component
			if len(l:remaining)
				echoerr 'malformed wildcard import "' .
					\ join(a:stmt.components, '.') . '"'
			endif
		elseif !util#IsValidJavaIdentifierComponent(l:component)
			" check if this component is a valid identifier
			echoerr 'unexpected identifier component "' . l:component . '"'
		endif

		if !has_key(l:root, l:component)
			let l:root[l:component] = {}
		endif

		let l:root = l:root[l:component]
	endfor

	return a:tree
endfunction

" Depending on configuration, process leaf nodes for `node`.
"
" If `g:java_import_wildcard_count` is a positive integer, merge
" any leafs in `node` into a wildcard. If zero, don't merge leafs in `node`.
" If negative, don't merge leafs in `node` and remove existing wildcard
" imports. See docs for specifcs.
function! s:MergeLeafsForNode(node)
	let l:merge_override = has_key(a:node, '*')

	" if wildcard_count is zero and we have a wildcard at this node,
	" merge leafs into it, otherwise do nothing
	if g:java_import_wildcard_count == 0 && !l:merge_override
		return a:node
	endif

	if has_key(a:node, '*')
		call remove(a:node, '*')
	endif

	if g:java_import_wildcard_count < 0
		return a:node
	endif

	if g:java_import_wildcard_count > 0 || l:merge_override
		" count number of leaf nodes
		let l:leaf_keys = []
		for key in keys(a:node)
			if !len(a:node[key])
				call add(l:leaf_keys, key)
			endif
		endfor

		" merge if it's greater than configured value
		if len(l:leaf_keys) >= g:java_import_wildcard_count || l:merge_override
			for key in l:leaf_keys
				call remove(a:node, key)
			endfor

			let a:node['*'] = {}
		endif
	endif

	return a:node
endfunction

" Merge `fq_classname` (a fully-qualified class name) into `tree`.
" Return the tree.
function! import_tree#Merge(tree, fq_classname, static = v:false)
	return s:MergeImportStatement(a:tree, {
		\ 'static': a:static,
		\ 'components': s:SplitQualifiedClassName(a:fq_classname)
		\ })
endfunction

" Flatten the import tree `tree` into a list of package imports `res`,
" returning `res`. Prepend `prefix` to each entry. Append `postfix` to each
" entry.
function! import_tree#Flatten(tree, res, prefix, postfix)
	call s:MergeLeafsForNode(a:tree)

	for [key, child] in items(a:tree)
		let l:path = a:prefix . key

		" recurse into chid trees
		if len(child)
			call import_tree#Flatten(child, a:res, l:path . '.', a:postfix)
		else
			call add(a:res, l:path . a:postfix)
		endif
	endfor

	return a:res
endfunction

" Read and remove import statements from the current buffer and return
" dictionary tree representations of the imported classes (static and
" non-static).
function! import_tree#Build() abort
	" find and remove import statements from buffer
	let l:imports = buffer#FilterLinesMatchingPattern('^\s*import\s.\+;\s*$')

	" generate import tree
	let l:import_tree = { 's': {}, 'ns': {} }
	for stmt in l:imports
		let l:import_stmt = s:TokenizeStatement(stmt)
		let l:import_tree = s:MergeImportStatement(l:import_tree, l:import_stmt)
	endfor
	
	return l:import_tree
endfunction

