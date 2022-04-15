" Build an import tree from the current buffer and return it. If `remove` is
" true, import statements are removed from the buffer.
function! import_tree#BuildFromBuffer(remove = v:false) abort
	return import_tree#BuildFromStatements(a:remove ?
		\ buffer#FilterLinesMatchingPattern(1, '^\s*import\s.\+;\s*$') :
		\ buffer#FindLinesMatchingPattern(1, '^\s*import\s.\+;\s*$'))
endfunction

" Build a tree from a list of import statements `stmts` and return it. Import
" statements must match the pattern '^\s*import\s.\+;\s*$', otherwise expect
" undefined behaviour.
"
" This function makes a reasonable effort to parse an import statement. It will
" try to split up a compound statement into individual imports.
function! import_tree#BuildFromStatements(stmts) abort
	let l:normalized_stmts = []
	for stmt in a:stmts
		call extend(l:normalized_stmts, s:NormalizeImportStatements(stmt))
	endfor

	let l:tree = s:TreeNodeInit()
	for [cmps, meta] in l:normalized_stmts
		call import_tree#Merge(l:tree, cmps, meta)
	endfor

	return l:tree
endfunction

" Merge `stmt` into `tree`, returning `tree`. `stmt` must be a fully-qualified
" class, method, or enum. `meta` defines properties for the leaf node.
"
" This function validates the import statement and may throw an error if the
" statement is invalid.
function! import_tree#Merge(tree, stmt, meta = {}) abort
	if type(a:stmt) == v:t_list
		let l:pkg_components = a:stmt
	else
		let l:pkg_components = split(a:stmt, '\.')
	endif

	if !len(l:pkg_components)
		echoerr 'bug: empty statement given'
	endif
	
	" check to see if the components are valid
	for i in range(len(l:pkg_components))
		let l:component = l:pkg_components[i]

		" the last component can be a wildcard '*'
		if i == (len(l:pkg_components) - 1) && l:pkg_components[i] == '*'
			continue
		endif

		" otherwise, ensure the component is a valid java identifier
		if !util#IsValidJavaIdentifierComponent(l:component)
			echoerr 'invalid import statement "' . a:stmt . '"'
		endif
	endfor

	" make way for leaf node
	let l:path = s:CreatePathInTree(a:tree, l:pkg_components[0:-2])
	
	" insert leaf
	let l:path.leaf[l:pkg_components[-1]] = a:meta

	return a:tree
endfunction

" Flatten `tree` into a flat list and return it.
"
" The `options` dictionary can be used to customize how the tree is flattened.
" The following options are supported:
" 	'prefix': <string>
" 		Prepend this string to each entry.
" 	'postfix': <string>
" 		Append this string to each entry
" 	'filter': <dictionary>
" 		The `filter` dictionary can be used to select which nodes in the tree to
" 		flatten. The keys/values map to the supported fields for leaf nodes:
" 			's': v:true/v:false (indicate whether to filter static/non-static
" 			entries)
" 	'initial': <list>
" 		Flatten tree into this list instead of a new one.
function! import_tree#Flatten(tree, options = {}) abort
	for key in keys(a:options)
		if index(['prefix', 'postfix', 'filter', 'initial'], key) < 0
			echoerr 'bug: "' . key . '" is not a supported option'
		endif
	endfor

	" set some defaults
	let l:opts = extend({
		\ 'prefix': '',
		\ 'postfix': '',
		\ 'filter': {},
		\ 'initial': [],
		\ '_path': []
		\ }, a:options)

	return s:FlattenInternal(a:tree, l:opts)
endfunction

" Create an empty node.
function! s:TreeNodeInit() abort
	return { 'leaf': {}, 'children': {} }
endfunction

function! s:NormalizeImportStatement(stmt)
	let l:matches = matchlist(a:stmt,
		\ '^import\s\+\(static\)\?\(.*\)$')
	if len(l:matches) < 3
		echoerr 'unexpected statement "' . a:stmt . '"'
	endif

	let l:matched = l:matches[0]
	let l:is_static = len(l:matches[1])
	let l:fq_import = substitute(l:matches[2], '\s', '', 'g')

	if !len(l:matched) || !len(l:fq_import)
		echoerr 'unexpected statement "' . a:stmt . '"'
	endif

	return [l:fq_import, { 's': l:is_static ? v:true : v:false }]
endfunction

" Build and return a normalized list of import statements from string `stmts`.
"
" The result will be a list of tuples [components, meta], with the following
" format:
" 	[['ca.example.package.MyClass', { 's': v:true }], ...]
"
" `components` is the fully-qualified import. `meta` is metadata for the
" import, which has the key 's' indicating whether it's a static import or not.
function! s:NormalizeImportStatements(stmts) abort
	let l:result = []

	for stmt in split(a:stmts, ';')
		let l:stmt = trim(substitute(stmt, '\s\+', ' ', 'g'))
		if !len(l:stmt)
			continue
		endif

		let l:normalized_stmt = s:NormalizeImportStatement(l:stmt)
		call add(l:result, l:normalized_stmt)
	endfor

	return l:result
endfunction

" Create a path within `tree` with nodes `nodes`, returning the newly created
" path within `tree`.
function! s:CreatePathInTree(tree, nodes) abort
	let l:node = a:tree
	for name in a:nodes
		" add leaf and children keys, if they don't exist already
		let l:node_prototype = s:TreeNodeInit()
		call extend(l:node, l:node_prototype, 'keep')
		call extend(l:node.children, { name: l:node_prototype }, 'keep')

		let l:node = l:node.children[name]
	endfor

	return l:node
endfunction

" Check whether a node should be flattened based on the filter and it's metadata.
function! s:ShouldFlattenNode(meta, filter) abort
	for [k, v] in items(a:filter)
		if !has_key(a:meta, k) || v != a:meta[k]
			return v:false
		endif
	endfor

	return v:true
endfunction

" Merge (or otherwise manipulate) leaf nodes according to configuration
" `g:java_import_wildcard_count`.
"
" See documentation for semantics of this option.
function! s:MergeLeafNodes(leafs) abort
	let l:leafs = extend({}, a:leafs)

	" nuclear: remove and let user fix imports
	if g:java_import_wildcard_count < 0
		if has_key(l:leafs, '*')
			call remove(l:leafs, '*')
		endif

		return l:leafs
	endif

	" sane: merge into a wildcard if one already exists
	if g:java_import_wildcard_count == 0
		if !has_key(l:leafs, '*')
			return l:leafs
		endif

		" assume non-static; this should be done smarter later
		return { '*': { 's': v:false } }
	endif

	" chaotic evil: merge into a wildcard if over a certain number
	let l:count = len(keys(l:leafs)) - (has_key(l:leafs, '*') ? 1 : 0)
	if l:count >= g:java_import_wildcard_count
		" assume non-static; this should be done smarter later
		return { '*': { 's': v:false } }
	endif

	return l:leafs
endfunction

" Same as import_tree#Flatten, but for internal use in this script.
" Doesn't do any checking on `options`, so that keys can be added and
" manipulated as needed.
"
" See public function doc for specifics.
function! s:FlattenInternal(tree, options)
	" first process any leaf nodes
	let l:merged_leaf_nodes = s:MergeLeafNodes(a:tree.leaf)
	for [name, meta] in items(l:merged_leaf_nodes)
		if s:ShouldFlattenNode(meta, a:options.filter)
			let l:fq_import = join(util#Flatten([a:options._path, name]), '.')
			call add(a:options.initial, a:options.prefix . l:fq_import . a:options.postfix)
		endif
	endfor

	" then recurse into children
	for [name, node] in items(a:tree.children)
		let l:new_path = util#Flatten([a:options._path, name])
		call s:FlattenInternal(node,
			\ extend({ '_path': l:new_path }, a:options, 'keep'))
	endfor

	return a:options.initial
endfunction

