" Build an import tree from the buffer `buf` and return it. If `remove` is
" true, import statements are removed from the buffer.
function! java_support#import_tree#BuildFromBuffer(buf = '%', remove = v:false) abort
	let l:patt = s:GetImportStmtPatt()
	return java_support#import_tree#BuildFromStatements(a:remove ?
		\ java_support#buffer#FilterLinesMatchingPattern(a:buf, 1, l:patt) :
		\ java_support#buffer#FindLinesMatchingPattern(a:buf, 1, l:patt))
endfunction

" Similar to #BuildFromBuffer, except merge statements into an existing tree.
function! java_support#import_tree#MergeFromBuffer(tree, buf = '%', remove = v:false) abort
	let l:patt = s:GetImportStmtPatt()
	return java_support#import_tree#MergeFromStatements(a:tree, a:remove ?
		\ java_support#buffer#FilterLinesMatchingPattern(a:buf, 1, l:patt) :
		\ java_support#buffer#FindLinesMatchingPattern(a:buf, 1, l:patt))
endfunction

" Build a new tree from a list of import statements `stmts` and return it.
" Import statements must match the pattern '^\s*import\s.\+;\s*$', otherwise
" expect undefined behaviour.
"
" This function makes a reasonable effort to parse an import statement. It will
" try to split up a compound statement into individual imports.
function! java_support#import_tree#BuildFromStatements(stmts) abort
	return java_support#import_tree#MergeFromStatements(
		\ java_support#import_tree#BuildEmpty(), a:stmts)
endfunction

" Similar to #BuildFromStatements, except statements are merged into an
" existing tree. Returns the tree. `stmts` is a list of import statements, as
" they would appear in the buffer.
function! java_support#import_tree#MergeFromStatements(tree, stmts) abort
	let l:normalized_stmts = []
	for stmt in a:stmts
		call extend(l:normalized_stmts, java_support#java#NormalizeImportStatements(stmt))
	endfor

	for [cmps, meta] in l:normalized_stmts
		call java_support#import_tree#Merge(a:tree, cmps, meta)
	endfor

	return a:tree
endfunction

" Read `file` and build a `tree` of the import statements, returning the tree.
" If the file is not a Java source file, expect undefined behaviour.
function! java_support#import_tree#BuildFromFile(file) abort
	return java_support#import_tree#MergeFromFile(
		\ java_support#import_tree#BuildEmpty(), a:file)
endfunction

" Read `file` and merge import statements into existing `tree`, returning
" `tree`. If the file is not a Java source file, expect undefined behaviour.
function! java_support#import_tree#MergeFromFile(tree, file) abort
	let l:patt = s:GetImportStmtPatt()

	let l:imports = []
	for line in readfile(a:file)
		if match(line, l:patt) >= 0
			call add(l:imports, line)
		endif
	endfor

	call java_support#import_tree#MergeFromStatements(a:tree, l:imports)
	return a:tree
endfunction

" Build an empty tree and return it.
function! java_support#import_tree#BuildEmpty() abort
	return s:TreeNodeInit()
endfunction

" Merge `stmt` into `tree`, returning `tree`. `stmt` must be a fully-qualified
" class, method, or enum, split into its components. `meta` defines properties
" for the leaf node.
"
" This function validates the import statement and may throw an error if the
" statement is invalid.
function! java_support#import_tree#Merge(tree, stmt, meta = {}) abort
	if empty(a:stmt)
		throw 'bug: empty statement given'
	endif
	
	" check to see if the components are valid
	for i in range(len(a:stmt))
		let l:component = a:stmt[i]

		" the last component can be a wildcard '*'
		if i == (len(a:stmt) - 1) && a:stmt[i] == '*'
			continue
		endif

		" otherwise, ensure the component is a valid java identifier
		if !java_support#java#IsValidIdentifier(l:component)
			throw 'invalid import statement "' . a:stmt . '"'
		endif
	endfor

	" make way for leaf node
	let l:path = s:CreatePathInTree(a:tree, a:stmt[0:-2])
	
	" insert leaf
	let l:path.leaf[a:stmt[-1]] = a:meta

	return a:tree
endfunction

" Merge two trees, returning a new tree.
function! java_support#import_tree#MergeTrees(tree_a, tree_b) abort
	let l:result = java_support#import_tree#BuildEmpty()

	function! s:TreeNodeVisitor(name, meta, path, acc) abort closure
		call java_support#import_tree#Merge(l:result, a:path, a:meta)
	endfunction

	call s:TraverseTree(a:tree_a,
		\ { name, meta, path, acc -> s:TreeNodeVisitor(name, meta, path, acc) },
		\ [], v:null)
	call s:TraverseTree(a:tree_b,
		\ { name, meta, path, acc -> s:TreeNodeVisitor(name, meta, path, acc) },
		\ [], v:null)

	return l:result
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
function! java_support#import_tree#Flatten(tree, options = {}) abort
	for key in keys(a:options)
		if index(['prefix', 'postfix', 'filter', 'initial'], key) < 0
			throw 'bug: "' . key . '" is not a supported option'
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

" Return an indexed representation of the given tree, used to quickly search
" for classes and their full package path.
function! java_support#import_tree#Index(tree, index = {}) abort
	return s:IndexInternal(a:tree, a:index, [])
endfunction

" Traverse `tree`, recursively indexing nodes into `index`.
function! s:IndexInternal(tree, index, path) abort
	" first process any leaf nodes
	for [name, meta] in items(a:tree.leaf)
		if !has_key(a:index, name)
			let a:index[name] = []
		endif

		let l:new_path = { 'fq_name': java_support#util#Flatten([a:path, name]), 'meta': meta }
		call add(a:index[name], l:new_path)
	endfor

	" then recurse into children
	for [name, node] in items(a:tree.children)
		let l:new_path = java_support#util#Flatten([a:path, name])
		call s:IndexInternal(node, a:index, l:new_path)
	endfor

	return a:index
endfunction

" Create an empty node.
function! s:TreeNodeInit() abort
	return { 'leaf': {}, 'children': {} }
endfunction

" Get the pattern used for matching import statements in Java source files.
function! s:GetImportStmtPatt() abort
	return '^\s*import\s.\+;\s*$'
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
function! s:FlattenInternal(tree, options) abort
	" first process any leaf nodes
	let l:merged_leaf_nodes = s:MergeLeafNodes(a:tree.leaf)
	for [name, meta] in items(l:merged_leaf_nodes)
		if s:ShouldFlattenNode(meta, a:options.filter)
			let l:fq_import = join(java_support#util#Flatten([a:options._path, name]), '.')
			call add(a:options.initial, a:options.prefix . l:fq_import . a:options.postfix)
		endif
	endfor

	" then recurse into children
	for [name, node] in items(a:tree.children)
		let l:new_path = java_support#util#Flatten([a:options._path, name])
		call s:FlattenInternal(node,
			\ extend({ '_path': l:new_path }, a:options, 'keep'))
	endfor

	return a:options.initial
endfunction

" Traverse the `tree`, executing `visitor` at each node in the tree.
"
" `visitor` is a funcref that accepts four arguments: the node name, the node
" metadata, the node path, and the accomulator (`initial`).
"
" `path` is a list representing the path to the current node (initially should
" be empty).
"
" Returns `initial`.
function! s:TraverseTree(tree, visitor, path, initial) abort
	" first process any leaf nodes
	for [name, meta] in items(a:tree.leaf)
		let l:node_path = java_support#util#Flatten([a:path, name])
		call a:visitor(name, meta, l:node_path, a:initial)
	endfor

	" then recurse into children
	for [name, node] in items(a:tree.children)
		let l:node_path = java_support#util#Flatten([a:path, name])
		call s:TraverseTree(node, a:visitor, l:node_path, a:initial)
	endfor

	return a:initial
endfunction

