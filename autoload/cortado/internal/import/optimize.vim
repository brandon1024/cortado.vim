" Create a new import tree handle.
function! cortado#internal#import#optimize#new() abort
	let l:handle = {}

	let l:handle.wildcards = function('s:wildcards')
	let l:handle.find_unused = function('s:find_unused')

	return l:handle
endfunction

" Optimize imports, merging wildcard imports according to
" g:cortado_import_wildcard_count.
function! s:wildcards(tree) abort
	let l:trees = cortado#internal#import#tree#new()

	function! s:tree_node_visitor(node, path, acc) abort
		let a:node.leaf = s:merge_leaf_nodes(a:node.leaf)
	endfunction

	call l:trees.visit_parents(a:tree, function('s:tree_node_visitor'), v:null)

	return a:tree
endfunction

" From a `tree`, find entries that are not referenced anywhere in buffer
" `buffer`, returning a tree of those unused imports. If `remove` is v:true,
" entries are removed from the given `tree`.
function! s:find_unused(tree, buffer = '%', remove = v:false) abort
	let l:trees = cortado#internal#import#tree#new()
	let l:buffers = cortado#internal#buffer#new()
	let l:utils = cortado#internal#util#new()

	function! s:tree_node_visitor(name, meta, path, acc) abort closure
		if a:name == '*'
			return
		endif

		" first, locate the import statement
		let l:starting_lnum = l:buffers.lnum_matching_patt(a:buffer, 1,
			\ 'import\s.*[^a-zA-Z$_]' . a:name . '\s*;') + 1

		let l:pattern = '\C\(^\|[^a-zA-Z$_]\)' . a:name . '\($\|[^a-zA-Z$_]\)'

		" if we found didn't find a match
		if !l:buffers.lnum_matching_patt(a:buffer, l:starting_lnum, l:pattern)
			call l:trees.merge(a:acc, a:path, a:meta)

			if a:remove
				call l:trees.remove(a:tree, a:path)
			endif
		endif
	endfunction

	return l:trees.visit_children(a:tree, function('s:tree_node_visitor'), l:trees.new())
endfunction

" Merge (or otherwise manipulate) leaf nodes according to configuration
" `g:cortado_import_wildcard_count`.
"
" See documentation for semantics of this option.
function! s:merge_leaf_nodes(leafs) abort
	let l:leafs = extend({}, a:leafs)

	" nuclear: remove and let user fix imports
	if g:cortado_import_wildcard_count < 0
		if has_key(l:leafs, '*')
			call remove(l:leafs, '*')
		endif

		return l:leafs
	endif

	" sane: merge into a wildcard if one already exists
	if g:cortado_import_wildcard_count == 0
		if !has_key(l:leafs, '*')
			return l:leafs
		endif

		" assume non-static; this should be done smarter later
		return { '*': { 's': v:false } }
	endif

	" chaotic evil: merge into a wildcard if over a certain number
	let l:count = len(keys(l:leafs)) - (has_key(l:leafs, '*') ? 1 : 0)
	if l:count >= g:cortado_import_wildcard_count
		" assume non-static; this should be done smarter later
		return { '*': { 's': v:false } }
	endif

	return l:leafs
endfunction

