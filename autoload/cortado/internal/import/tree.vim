" Create a new import tree handle.
function! cortado#internal#import#tree#new() abort
	let l:handle = {}

	let l:handle.from_buffer = function('s:from_buffer')
	let l:handle.merge_from_buffer = function('s:merge_from_buffer')
	let l:handle.from_statements = function('s:from_statements')
	let l:handle.merge_from_statements = function('s:merge_from_statements')
	let l:handle.from_file = function('s:from_file')
	let l:handle.merge_from_file = function('s:merge_from_file')
	let l:handle.new = function('s:new')
	let l:handle.merge = function('s:merge')
	let l:handle.merge_trees = function('s:merge_trees')
	let l:handle.flatten = function('s:flatten')
	let l:handle.index = function('s:index')
	let l:handle.visit_children = function('s:visit_children')
	let l:handle.visit_parents = function('s:visit_parents')
	let l:handle.remove = function('s:remove')

	return l:handle
endfunction

" Build an import tree from the buffer `buf` and return it. If `remove` is
" true, import statements are removed from the buffer.
function! s:from_buffer(buf = '%', remove = v:false) abort
	let l:buffers = cortado#internal#buffer#new()

	let l:patt = s:get_import_statement_patt()
	return s:from_statements(a:remove ?
		\ l:buffers.filter_lines_matching_patt(a:buf, 1, l:patt) :
		\ l:buffers.lines_matching_patt(a:buf, 1, l:patt))
endfunction

" Similar to #from_buffer, except merge statements into an existing tree.
function! s:merge_from_buffer(tree, buf = '%', remove = v:false) abort
	let l:buffers = cortado#internal#buffer#new()

	let l:patt = s:get_import_statement_patt()
	return s:merge_from_statements(a:tree, a:remove ?
		\ l:buffers.filter_lines_matching_patt(a:buf, 1, l:patt) :
		\ l:buffers.lines_matching_patt(a:buf, 1, l:patt))
endfunction

" Build a new tree from a list of import statements `stmts` and return it.
" Import statements must match the pattern '^\s*import\s.\+;\s*$', otherwise
" expect undefined behaviour.
"
" This function makes a reasonable effort to parse an import statement. It will
" try to split up a compound statement into individual imports.
function! s:from_statements(stmts) abort
	return s:merge_from_statements(s:new(), a:stmts)
endfunction

" Similar to #from_statements, except statements are merged into an
" existing tree. Returns the tree. `stmts` is a list of import statements, as
" they would appear in the buffer.
function! s:merge_from_statements(tree, stmts) abort
	let l:java = cortado#internal#java#new()

	let l:normalized_stmts = []
	for stmt in a:stmts
		call extend(l:normalized_stmts, l:java.normalize_import_statements(stmt))
	endfor

	for [cmps, meta] in l:normalized_stmts
		call s:merge(a:tree, cmps, meta)
	endfor

	return a:tree
endfunction

" Read `file` and build a `tree` of the import statements, returning the tree.
" If the file is not a Java source file, expect undefined behaviour.
function! s:from_file(file) abort
	return s:merge_from_file(s:new(), a:file)
endfunction

" Read `file` and merge import statements into existing `tree`, returning
" `tree`. If the file is not a Java source file, expect undefined behaviour.
function! s:merge_from_file(tree, file) abort
	let l:patt = s:get_import_statement_patt()

	let l:imports = []
	for line in readfile(a:file)
		if match(line, l:patt) >= 0
			call add(l:imports, line)
		endif
	endfor

	call s:merge_from_statements(a:tree, l:imports)
	return a:tree
endfunction

" Build an empty tree and return it.
function! s:new() abort
	return { 'leaf': {}, 'children': {} }
endfunction

" Merge `stmt` into `tree`, returning `tree`. `stmt` must be a fully-qualified
" class, method, or enum, split into its components. `meta` defines properties
" for the leaf node.
"
" This function validates the import statement and may throw an error if the
" statement is invalid.
function! s:merge(tree, stmt, meta = {}) abort
	let l:java = cortado#internal#java#new()

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
		if !l:java.is_valid_identifier(l:component)
			throw 'invalid import statement "' . a:stmt . '"'
		endif
	endfor

	" make way for leaf node
	let l:path = s:create_path_in_tree(a:tree, a:stmt[0:-2])
	
	" insert leaf
	let l:path.leaf[a:stmt[-1]] = a:meta

	return a:tree
endfunction

" Merge two trees, returning a new tree.
function! s:merge_trees(tree_a, tree_b) abort
	let l:result = s:new()

	function! s:tree_node_visitor(name, meta, path, acc) abort
		call s:merge(a:acc, a:path, a:meta)
	endfunction

	call s:visit_children(a:tree_a, function('s:tree_node_visitor'), l:result)
	call s:visit_children(a:tree_b, function('s:tree_node_visitor'), l:result)

	return l:result
endfunction

" Flatten `tree` into a flat list of strings and return it.
"
" The `options` dictionary can be used to customize how the tree is flattened.
" The following options are supported:
" 	'prefix': <string>
" 		Prepend this string to each entry.
" 	'postfix': <string>
" 		Append this string to each entry
" 	'filter': <dictionary>
" 		The `filter` dictionary can be used to select which nodes in the tree to
" 		flatten.
" 			's': boolean indicating whether to filter static/non-static
" 			entries
" 			'f': a predicate that accepts the node and indicates whether the
" 			node should be included or not
" 			'r': boolean indicating whether to remove filtered nodes from the
" 			tree
" 	'initial': <list>
" 		Flatten tree into this list instead of a new one.
" 	'sort': v:true/v:false
" 		Sort the result. Defaults to false.
function! s:flatten(tree, options = {}) abort
	for key in keys(a:options)
		if index(['prefix', 'postfix', 'filter', 'initial', 'sort'], key) < 0
			throw 'bug: "' . key . '" is not a supported option'
		endif
	endfor

	" set some defaults
	let l:opts = extend({
		\ 'prefix': '',
		\ 'postfix': '',
		\ 'filter': {},
		\ 'initial': [],
		\ 'sort': v:false,
		\ '_path': []
		\ }, a:options)

	function! s:should_flatten(path, meta, filter) abort
		for [k, VALUE] in items(a:filter)
			" filter static / non-static
			if k == 's' && a:meta.s != VALUE
				return v:false
			endif

			" filter by user-defined predicate
			if k == 'f' && !VALUE(a:path, a:meta)
				return v:false
			endif
		endfor

		return v:true
	endfunction

	function! s:tree_node_visitor(name, meta, path, result) abort closure
		if s:should_flatten(a:path, a:meta, l:opts.filter)
			let l:formatted = l:opts.prefix . join(a:path, '.') . l:opts.postfix
			call add(a:result, l:formatted)

			" if instructed to remove flattened nodes from source tree
			if get(l:opts.filter, 'r', v:false)
				call s:remove(a:tree, a:path)
			endif
		endif
	endfunction

	let l:result = s:visit_children(a:tree, function('s:tree_node_visitor'),
		\ l:opts.initial)

	if l:opts.sort
		return sort(l:result)
	endif

	return l:result
endfunction

" Return an indexed representation of the given tree, used to quickly search
" for classes and their full package path.
function! s:index(tree, index = {}) abort
	function! s:tree_node_visitor(name, meta, path, index) abort
		if !has_key(a:index, a:name)
			let a:index[a:name] = []
		endif

		let l:new_path = { 'fq_name': a:path, 'meta': a:meta }
		call add(a:index[a:name], l:new_path)
	endfunction

	call s:visit_children(a:tree, function('s:tree_node_visitor'), a:index)

	return a:index
endfunction

" Traverse the `tree`, executing a `visitor` at each child node in the tree.
" See s:traverse_tree().
function! s:visit_children(tree, visitor, acc = v:null) abort
	let l:utils = cortado#internal#util#new()

	function! s:parent_visitor(node, path, acc) abort closure
		for [name, meta] in items(a:node.leaf)
			let l:node_path = l:utils.flatten([a:path, name])
			call a:visitor(name, meta, l:node_path, a:acc)
		endfor
	endfunction

	return s:traverse_tree(a:tree, function('s:parent_visitor'), [], a:acc)
endfunction

" Traverse the `tree`, executing a `visitor` at each parent node in the tree.
" See s:traverse_tree().
function! s:visit_parents(tree, visitor, acc = v:null) abort
	return s:traverse_tree(a:tree, a:visitor, [], a:acc)
endfunction

" Remove a node from the tree. Returns whether or not the node existed in the
" tree.
function! s:remove(tree, path) abort
	let l:leaf_name = remove(a:path, -1)

	let l:node = a:tree
	for node_name in a:path
		let l:node = l:node.children
		if !has_key(l:node, node_name)
			return v:false
		endif

		let l:node = l:node[node_name]
	endfor

	let l:node = l:node.leaf
	if !has_key(l:node, l:leaf_name)
		return v:false
	endif

	call remove(l:node, l:leaf_name)

	return v:true
endfunction

" Traverse the `tree`, executing a `visitor` at each node in the tree.
"
" `parent_visitor` is a funcref that is executed at each parent node in the
" tree. The function accepts tree arguments, the parent node, the node path
" and the accomulator `acc`.
"
" `child_visitor` is a funcref that is executed at each child node in the
" tree. The function accepts four arguments, the node name, the node metadata,
" the node path, and the accomulator `acc`.
"
" `path` is a list representing the path to the current node (initially should
" be empty).
"
" Returns `acc`.
function! s:traverse_tree(tree, visitor, path, acc) abort
	let l:utils = cortado#internal#util#new()

	" then recurse into children
	for [name, node] in items(a:tree.children)
		let l:node_path = l:utils.flatten([a:path, name])

		call a:visitor(node, l:node_path, a:acc)

		call s:traverse_tree(node, a:visitor, l:node_path, a:acc)
	endfor

	return a:acc
endfunction

" Create a path within `tree` with nodes `nodes`, returning the newly created
" path within `tree`.
function! s:create_path_in_tree(tree, nodes) abort
	let l:node = a:tree
	for name in a:nodes
		" add leaf and children keys, if they don't exist already
		let l:node_prototype = s:new()
		call extend(l:node, l:node_prototype, 'keep')
		call extend(l:node.children, { name: l:node_prototype }, 'keep')

		let l:node = l:node.children[name]
	endfor

	return l:node
endfunction

" Get the pattern used for matching import statements in Java source files.
function! s:get_import_statement_patt() abort
	return '^\s*import\s.\+;\s*$'
endfunction

